using Fireman.GameCore.Abstractions;
using Fireman.GameCore.Events;
using Fireman.GameCore.Model;
using Fireman.GameCore.Randomness;

namespace Fireman.GameCore.Simulation;

public sealed class MatchConfig
{
    public int Columns { get; init; } = WorldState.Columns;
    public int Rows { get; init; } = WorldState.Rows;
    public int FuseTicks { get; init; } = 66; // ~2.2 seconds at 30 ticks/s
    public int FlameDurationTicks { get; init; } = 15; // 0.5s at 30 ticks/s
    public int BarrelDropRatePercent { get; init; } = 40;
    public int PlayerCount { get; init; } = 4;
    public int InitialSeed { get; init; } = 12345;
}

public sealed class MatchSimulation : ITickSource
{
    private readonly MatchConfig _config;
    private readonly IRandom _rng;
    private readonly WorldState _state = new();
    private readonly List<SimEvent> _events = new();
    private int _nextBombId = 1;
    private int _nextPowerUpId = 1;

    public long CurrentTick => _state.Tick;
    public WorldState State => _state;

    public MatchSimulation(MatchConfig? config = null, IRandom? rng = null)
    {
        _config = config ?? new MatchConfig();
        _rng = rng ?? new SeededRandom(_config.InitialSeed);
        InitializeWorld();
    }

    private void InitializeWorld()
    {
        // 1. Generate grid walls: alternating pillars at even coordinates (like Bomberman)
        for (int y = 0; y < _config.Rows; y++)
        {
            for (int x = 0; x < _config.Columns; x++)
            {
                if (x % 2 == 1 && y % 2 == 1)
                {
                    _state.SetTile(x, y, TileType.Wall);
                }
                else
                {
                    _state.SetTile(x, y, TileType.Empty);
                }
            }
        }

        // 2. Corner safe zones (no barrels around 4 starting positions)
        var safeTiles = new HashSet<(int X, int Y)>
        {
            (0, 0), (1, 0), (0, 1),
            (_config.Columns - 1, 0), (_config.Columns - 2, 0), (_config.Columns - 1, 1),
            (0, _config.Rows - 1), (1, _config.Rows - 1), (0, _config.Rows - 2),
            (_config.Columns - 1, _config.Rows - 1), (_config.Columns - 2, _config.Rows - 1), (_config.Columns - 1, _config.Rows - 2)
        };

        // 3. Place destructible barrels randomly based on seed
        for (int y = 0; y < _config.Rows; y++)
        {
            for (int x = 0; x < _config.Columns; x++)
            {
                if (_state.GetTile(x, y) == TileType.Empty && !safeTiles.Contains((x, y)))
                {
                    if (_rng.Next(100) < 65) // 65% barrel density
                    {
                        _state.SetTile(x, y, TileType.Barrel);
                    }
                }
            }
        }

        // 4. Setup Players in the corners
        var spawnTiles = new (int X, int Y)[]
        {
            (0, 0),
            (_config.Columns - 1, _config.Rows - 1),
            (_config.Columns - 1, 0),
            (0, _config.Rows - 1)
        };

        for (int i = 0; i < _config.PlayerCount && i < spawnTiles.Length; i++)
        {
            var spawn = spawnTiles[i];
            _state.Players.Add(new PlayerState
            {
                Id = i + 1,
                Name = $"Player {i + 1}",
                Position = FixedPos.FromTile(spawn.X, spawn.Y),
                Health = 100,
                BombCapacity = 1,
                BombRange = 1,
                MoveSpeedSubUnitsPerTick = 8,
                IsAlive = true
            });
        }
    }

    public TickResult Step(ReadOnlySpan<PlayerInput> inputs)
    {
        _events.Clear();
        _state.Tick++;

        if (!_state.IsMatchOver)
        {
            ApplyInputs(inputs);
            TickBombs();
            ResolveExplosions();
            TickFlames();
            CollectPowerUps();
            EvaluateRules();
        }

        return new TickResult(_state.Tick, _state.ComputeHash(), _events.ToArray());
    }

    private void ApplyInputs(ReadOnlySpan<PlayerInput> inputs)
    {
        foreach (var input in inputs)
        {
            var player = _state.Players.FirstOrDefault(p => p.Id == input.PlayerId);
            if (player is null || !player.IsAlive) continue;

            player.LastProcessedSeq = input.Seq;

            // Handle bomb placement
            if (input.PlaceBomb && player.ActiveBombs < player.BombCapacity)
            {
                int tileX = player.Position.TileX;
                int tileY = player.Position.TileY;

                bool bombExists = _state.Bombs.Any(b => b.TileX == tileX && b.TileY == tileY);
                if (!bombExists && _state.GetTile(tileX, tileY) == TileType.Empty)
                {
                    var bomb = new BombState
                    {
                        Id = _nextBombId++,
                        OwnerPlayerId = player.Id,
                        TileX = tileX,
                        TileY = tileY,
                        Range = player.BombRange,
                        RemainingTicks = _config.FuseTicks
                    };

                    _state.Bombs.Add(bomb);
                    player.ActiveBombs++;
                    _events.Add(new SimEvent(SimEventType.BombPlaced, player.Id, tileX, tileY, bomb.Id));
                }
            }

            // Handle movement
            if (input.MoveDir != Direction.None)
            {
                MovePlayer(player, input.MoveDir);
            }
        }
    }

    private void MovePlayer(PlayerState player, Direction dir)
    {
        int deltaX = 0;
        int deltaY = 0;
        int step = player.MoveSpeedSubUnitsPerTick;

        switch (dir)
        {
            case Direction.Up: deltaY = -step; break;
            case Direction.Down: deltaY = step; break;
            case Direction.Left: deltaX = -step; break;
            case Direction.Right: deltaX = step; break;
        }

        int targetRawX = player.Position.RawX + deltaX;
        int targetRawY = player.Position.RawY + deltaY;

        // Collision bounds check with board
        int maxRawX = _config.Columns * FixedPos.SubUnitsPerTile - 1;
        int maxRawY = _config.Rows * FixedPos.SubUnitsPerTile - 1;

        targetRawX = Math.Clamp(targetRawX, 0, maxRawX);
        targetRawY = Math.Clamp(targetRawY, 0, maxRawY);

        // Check tile collision: player occupies bounding box of 70% tile size (approx 180 / 256 subunits)
        int halfSize = 80;
        int minTileX = (targetRawX - halfSize) / FixedPos.SubUnitsPerTile;
        int maxTileX = (targetRawX + halfSize) / FixedPos.SubUnitsPerTile;
        int minTileY = (targetRawY - halfSize) / FixedPos.SubUnitsPerTile;
        int maxTileY = (targetRawY + halfSize) / FixedPos.SubUnitsPerTile;

        bool blocked = false;
        for (int ty = minTileY; ty <= maxTileY; ty++)
        {
            for (int tx = minTileX; tx <= maxTileX; tx++)
            {
                var tile = _state.GetTile(tx, ty);
                if (tile == TileType.Wall || tile == TileType.Barrel)
                {
                    blocked = true;
                    break;
                }

                // Bomb collision: solid unless player was already inside this bomb's tile when it was placed
                var bombAtTile = _state.Bombs.FirstOrDefault(b => b.TileX == tx && b.TileY == ty);
                if (bombAtTile != null)
                {
                    bool wasInsideCurrent = (player.Position.TileX == tx && player.Position.TileY == ty);
                    if (!wasInsideCurrent)
                    {
                        blocked = true;
                        break;
                    }
                }
            }
            if (blocked) break;
        }

        if (!blocked)
        {
            player.Position = FixedPos.FromSubUnits(targetRawX, targetRawY);
        }
    }

    private void TickBombs()
    {
        for (int i = 0; i < _state.Bombs.Count; i++)
        {
            _state.Bombs[i].RemainingTicks--;
        }
    }

    private void ResolveExplosions()
    {
        // Find bombs that reached 0 ticks
        var explodingBombsQueue = new Queue<BombState>();
        for (int i = _state.Bombs.Count - 1; i >= 0; i--)
        {
            if (_state.Bombs[i].RemainingTicks <= 0)
            {
                explodingBombsQueue.Enqueue(_state.Bombs[i]);
                _state.Bombs.RemoveAt(i);
            }
        }

        if (explodingBombsQueue.Count == 0) return;

        var processedBombs = new HashSet<int>();

        // BFS chain reaction: exploding bombs ignite adjacent bombs
        while (explodingBombsQueue.Count > 0)
        {
            var bomb = explodingBombsQueue.Dequeue();
            if (!processedBombs.Add(bomb.Id)) continue;

            // Free owner player's active bomb count
            var owner = _state.Players.FirstOrDefault(p => p.Id == bomb.OwnerPlayerId);
            if (owner != null && owner.ActiveBombs > 0)
            {
                owner.ActiveBombs--;
            }

            _events.Add(new SimEvent(SimEventType.BombExploded, bomb.OwnerPlayerId, bomb.TileX, bomb.TileY, bomb.Id));
            AddFlameTile(bomb.TileX, bomb.TileY, bomb.OwnerPlayerId);

            // 4 directions: Up, Down, Left, Right
            ReadOnlySpan<(int dx, int dy)> directions = [(0, -1), (0, 1), (-1, 0), (1, 0)];

            foreach (var (dx, dy) in directions)
            {
                for (int step = 1; step <= bomb.Range; step++)
                {
                    int targetX = bomb.TileX + dx * step;
                    int targetY = bomb.TileY + dy * step;

                    if (targetX < 0 || targetX >= _config.Columns || targetY < 0 || targetY >= _config.Rows)
                        break;

                    var tile = _state.GetTile(targetX, targetY);
                    if (tile == TileType.Wall)
                    {
                        // Walls stop flame completely
                        break;
                    }

                    if (tile == TileType.Barrel)
                    {
                        // Destroys barrel, flame stops here
                        _state.SetTile(targetX, targetY, TileType.Empty);
                        if (owner != null) owner.Score += 100;
                        _events.Add(new SimEvent(SimEventType.BarrelDestroyed, bomb.OwnerPlayerId, targetX, targetY));
                        AddFlameTile(targetX, targetY, bomb.OwnerPlayerId);

                        // Chance to drop power-up
                        if (_rng.Next(100) < _config.BarrelDropRatePercent)
                        {
                            var powerUpType = (PowerUpType)_rng.Next(1, 5);
                            var pup = new PowerUpState
                            {
                                Id = _nextPowerUpId++,
                                TileX = targetX,
                                TileY = targetY,
                                Type = powerUpType
                            };
                            _state.PowerUps.Add(pup);
                            _events.Add(new SimEvent(SimEventType.PowerUpSpawned, (int)powerUpType, targetX, targetY, pup.Id));
                        }
                        break;
                    }

                    // Check if another bomb is in this path -> Chain explosion!
                    var chainedBomb = _state.Bombs.FirstOrDefault(b => b.TileX == targetX && b.TileY == targetY);
                    if (chainedBomb != null)
                    {
                        _state.Bombs.Remove(chainedBomb);
                        explodingBombsQueue.Enqueue(chainedBomb);
                    }

                    AddFlameTile(targetX, targetY, bomb.OwnerPlayerId);
                }
            }
        }
    }

    private void AddFlameTile(int x, int y, int ownerPlayerId)
    {
        var existing = _state.Flames.FirstOrDefault(f => f.TileX == x && f.TileY == y);
        if (existing != null)
        {
            existing.RemainingTicks = _config.FlameDurationTicks;
        }
        else
        {
            _state.Flames.Add(new FlameTile
            {
                TileX = x,
                TileY = y,
                RemainingTicks = _config.FlameDurationTicks,
                OwnerPlayerId = ownerPlayerId
            });
        }

        // Destroy any power-up currently caught in flame
        for (int i = _state.PowerUps.Count - 1; i >= 0; i--)
        {
            if (_state.PowerUps[i].TileX == x && _state.PowerUps[i].TileY == y)
            {
                _state.PowerUps.RemoveAt(i);
            }
        }
    }

    private void TickFlames()
    {
        for (int i = _state.Flames.Count - 1; i >= 0; i--)
        {
            var flame = _state.Flames[i];
            flame.RemainingTicks--;

            // Check damage against players in this tile
            foreach (var player in _state.Players.Where(p => p.IsAlive))
            {
                if (player.Position.TileX == flame.TileX && player.Position.TileY == flame.TileY)
                {
                    if (!flame.DamagedPlayerIds.Add(player.Id)) continue;
                    player.Health = Math.Max(0, player.Health - 25);
                    var attacker = _state.Players.FirstOrDefault(p => p.Id == flame.OwnerPlayerId);
                    if (attacker != null && attacker.Id != player.Id) attacker.Score += 1000;
                    _events.Add(new SimEvent(SimEventType.PlayerDamaged, player.Id, flame.TileX, flame.TileY, player.Health));

                    if (player.Health <= 0)
                    {
                        player.IsAlive = false;
                        _events.Add(new SimEvent(SimEventType.PlayerDied, player.Id, flame.TileX, flame.TileY));
                    }
                }
            }

            if (flame.RemainingTicks <= 0)
            {
                _state.Flames.RemoveAt(i);
            }
        }
    }

    private void CollectPowerUps()
    {
        for (int i = _state.PowerUps.Count - 1; i >= 0; i--)
        {
            var pup = _state.PowerUps[i];
            var player = _state.Players.FirstOrDefault(p => p.IsAlive && p.Position.TileX == pup.TileX && p.Position.TileY == pup.TileY);
            if (player != null)
            {
                switch (pup.Type)
                {
                    case PowerUpType.Lightning:
                        player.BombRange++;
                        break;
                    case PowerUpType.Shoe:
                        player.MoveSpeedSubUnitsPerTick += 2; // +25% speed
                        break;
                    case PowerUpType.Bomb:
                        player.BombCapacity++;
                        break;
                    case PowerUpType.Heal:
                        player.Health = Math.Min(100, player.Health + 10);
                        break;
                }
                player.Score += 500;

                _events.Add(new SimEvent(SimEventType.PowerUpCollected, player.Id, pup.TileX, pup.TileY, (int)pup.Type));
                _state.PowerUps.RemoveAt(i);
            }
        }
    }

    private void EvaluateRules()
    {
        int aliveCount = _state.Players.Count(p => p.IsAlive);
        if (_state.Players.Count > 1 && aliveCount <= 1)
        {
            _state.IsMatchOver = true;
            _state.WinnerPlayerId = _state.Players.FirstOrDefault(p => p.IsAlive)?.Id;
            _events.Add(new SimEvent(SimEventType.MatchEnded, _state.WinnerPlayerId ?? 0, 0, 0));
        }
    }
}

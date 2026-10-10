using System.Collections.Concurrent;
using Fireman.Contracts.Matches;
using Fireman.GameCore.Model;
using Fireman.GameCore.Simulation;
using Microsoft.AspNetCore.SignalR;

namespace Fireman.Api.Hubs;

/// <summary>
/// Manages active game matches, running deterministic 30Hz simulation loops
/// and broadcasting authoritative WorldSnapshot updates at 20Hz.
/// </summary>
public interface IMatchHostManager
{
    void CreateOrJoinMatch(string matchId, int playerCount = 4);
    void EnqueueInput(string matchId, PlayerInputDto input);
    void RemoveMatch(string matchId);
}

public sealed class MatchHostManager : IMatchHostManager, IDisposable
{
    private readonly IHubContext<MatchHub> _hubContext;
    private readonly ILogger<MatchHostManager> _logger;
    private readonly ConcurrentDictionary<string, ActiveMatchSession> _matches = new();

    public MatchHostManager(IHubContext<MatchHub> hubContext, ILogger<MatchHostManager> logger)
    {
        _hubContext = hubContext;
        _logger = logger;
    }

    public void CreateOrJoinMatch(string matchId, int playerCount = 4)
    {
        _matches.GetOrAdd(matchId, id =>
        {
            var session = new ActiveMatchSession(id, playerCount, _hubContext, _logger);
            session.Start();
            return session;
        });
    }

    public void EnqueueInput(string matchId, PlayerInputDto input)
    {
        if (_matches.TryGetValue(matchId, out var session))
        {
            session.EnqueueInput(input);
        }
    }

    public void RemoveMatch(string matchId)
    {
        if (_matches.TryRemove(matchId, out var session))
        {
            session.Dispose();
        }
    }

    public void Dispose()
    {
        foreach (var session in _matches.Values)
        {
            session.Dispose();
        }
        _matches.Clear();
    }
}

internal sealed class ActiveMatchSession : IDisposable
{
    private readonly string _matchId;
    private readonly IHubContext<MatchHub> _hubContext;
    private readonly ILogger _logger;
    private readonly MatchSimulation _simulation;
    private readonly ConcurrentQueue<PlayerInputDto> _inputQueue = new();
    private readonly CancellationTokenSource _cts = new();
    private Task? _loopTask;
    private readonly ConcurrentDictionary<Guid, int> _playerSlotMap = new();
    private int _nextSlot = 1;

    public ActiveMatchSession(string matchId, int playerCount, IHubContext<MatchHub> hubContext, ILogger logger)
    {
        _matchId = matchId;
        _hubContext = hubContext;
        _logger = logger;
        _simulation = new MatchSimulation(new MatchConfig
        {
            PlayerCount = playerCount,
            InitialSeed = matchId.GetHashCode()
        });
    }

    public void Start()
    {
        _loopTask = Task.Run(SimulationLoopAsync);
    }

    public void EnqueueInput(PlayerInputDto input)
    {
        _inputQueue.Enqueue(input);
    }

    private int GetOrCreateSlot(Guid userId)
    {
        return _playerSlotMap.GetOrAdd(userId, _ => _nextSlot++);
    }

    private async Task SimulationLoopAsync()
    {
        // 30 Hz fixed time step (33.33ms per tick)
        using var timer = new PeriodicTimer(TimeSpan.FromMilliseconds(33.33));
        long tickCount = 0;
        long lastAckedSeq = 0;

        try
        {
            while (await timer.WaitForNextTickAsync(_cts.Token))
            {
                tickCount++;

                // 1. Drain incoming inputs for this tick
                var inputsToApply = new List<PlayerInput>();
                while (_inputQueue.TryDequeue(out var inputDto))
                {
                    int slot = GetOrCreateSlot(inputDto.UserId);
                    inputsToApply.Add(new PlayerInput(
                        PlayerId: slot,
                        Seq: inputDto.Seq,
                        Tick: tickCount,
                        MoveDir: (Direction)inputDto.MoveDir,
                        PlaceBomb: inputDto.PlaceBomb
                    ));
                    if (inputDto.Seq > lastAckedSeq)
                    {
                        lastAckedSeq = inputDto.Seq;
                    }
                }

                // 2. Authoritative step in GameCore
                var tickResult = _simulation.Step(inputsToApply.ToArray());

                // 3. Broadcast snapshot to players at ~20Hz (every tick or 2 out of 3 ticks)
                if (tickCount % 2 == 0 || _simulation.State.IsMatchOver)
                {
                    var snapshot = CreateSnapshotDto(tickResult.Tick, tickResult.WorldHash, lastAckedSeq);
                    await _hubContext.Clients.Group(_matchId).SendAsync("WorldSnapshotReceived", snapshot, _cts.Token);
                }

                if (_simulation.State.IsMatchOver)
                {
                    _logger.LogInformation("Match {MatchId} finished. Winner: {WinnerId}", _matchId, _simulation.State.WinnerPlayerId);
                    break;
                }
            }
        }
        catch (OperationCanceledException)
        {
            // Session disposed
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in MatchSimulation loop for match {MatchId}", _matchId);
        }
    }

    private WorldSnapshotDto CreateSnapshotDto(long tick, ulong hash, long lastSeq)
    {
        var players = _simulation.State.Players.Select(p => new PlayerSnapshotDto(
            PlayerId: p.Id,
            UserId: _playerSlotMap.FirstOrDefault(kv => kv.Value == p.Id).Key,
            SubTileX: p.Position.RawX,
            SubTileY: p.Position.RawY,
            Health: p.Health,
            BombCapacity: p.BombCapacity,
            BombRange: p.BombRange,
            Speed: p.MoveSpeedSubUnitsPerTick,
            IsAlive: p.IsAlive
        )).ToList();

        var bombs = _simulation.State.Bombs.Select(b => new BombSnapshotDto(
            BombId: b.Id,
            TileX: b.TileX,
            TileY: b.TileY,
            RemainingTicks: b.RemainingTicks,
            Range: b.Range
        )).ToList();

        var flames = _simulation.State.Flames.Select(f => new FlameSnapshotDto(
            TileX: f.TileX,
            TileY: f.TileY,
            RemainingTicks: f.RemainingTicks
        )).ToList();

        var powerUps = _simulation.State.PowerUps.Select(p => new PowerUpSnapshotDto(
            Id: p.Id,
            TileX: p.TileX,
            TileY: p.TileY,
            Type: (byte)p.Type
        )).ToList();

        return new WorldSnapshotDto(
            MatchId: Guid.TryParse(_matchId, out var g) ? g : Guid.Empty,
            Tick: tick,
            WorldHash: hash,
            LastAckedSeq: lastSeq,
            Players: players,
            Bombs: bombs,
            Flames: flames,
            PowerUps: powerUps,
            IsMatchOver: _simulation.State.IsMatchOver,
            WinnerId: _simulation.State.WinnerPlayerId
        );
    }

    public void Dispose()
    {
        _cts.Cancel();
        _cts.Dispose();
    }
}

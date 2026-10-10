using System.Collections.Concurrent;
using System.Diagnostics;
using System.Threading.Channels;
using Fireman.Contracts.Matches;
using Fireman.GameCore.Model;
using Fireman.GameCore.Replay;
using Fireman.GameCore.Simulation;
using Microsoft.AspNetCore.SignalR;

namespace Fireman.Api.Hubs;

/// <summary>
/// Manages active game matches, running deterministic 30Hz simulation loops
/// with drift compensation and broadcasting authoritative WorldSnapshot updates at 20Hz.
/// </summary>
public interface IMatchHostManager
{
    void CreateOrJoinMatch(string matchId, int playerCount = 4);
    void EnqueueInput(string matchId, PlayerInputDto input);
    void RemoveMatch(string matchId);
    MatchReplay? GetMatchReplay(string matchId);
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

    public MatchReplay? GetMatchReplay(string matchId)
    {
        return _matches.TryGetValue(matchId, out var session) ? session.Replay : null;
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
    private const double MillisecondsPerTick = 1000.0 / 30.0; // ~33.333 ms

    private readonly string _matchId;
    private readonly IHubContext<MatchHub> _hubContext;
    private readonly ILogger _logger;
    private readonly MatchSimulation _simulation;
    private readonly Channel<PlayerInputDto> _inputChannel = Channel.CreateUnbounded<PlayerInputDto>(new UnboundedChannelOptions
    {
        SingleReader = true,
        SingleWriter = false
    });
    private readonly CancellationTokenSource _cts = new();
    private Task? _loopTask;
    private readonly ConcurrentDictionary<Guid, int> _playerSlotMap = new();
    private int _nextSlot = 1;

    public MatchReplay Replay { get; }

    public ActiveMatchSession(string matchId, int playerCount, IHubContext<MatchHub> hubContext, ILogger logger)
    {
        _matchId = matchId;
        _hubContext = hubContext;
        _logger = logger;
        int seed = matchId.GetHashCode();

        _simulation = new MatchSimulation(new MatchConfig
        {
            PlayerCount = playerCount,
            InitialSeed = seed
        });

        Replay = new MatchReplay
        {
            MatchId = Guid.TryParse(matchId, out var g) ? g : Guid.NewGuid(),
            InitialSeed = seed,
            PlayerCount = playerCount
        };
    }

    public void Start()
    {
        _loopTask = Task.Run(SimulationLoopAsync);
    }

    public void EnqueueInput(PlayerInputDto input)
    {
        _inputChannel.Writer.TryWrite(input);
    }

    private int GetOrCreateSlot(Guid userId)
    {
        return _playerSlotMap.GetOrAdd(userId, _ => _nextSlot++);
    }

    private async Task SimulationLoopAsync()
    {
        long tickCount = 0;
        long lastAckedSeq = 0;
        var stopwatch = Stopwatch.StartNew();

        try
        {
            while (!_cts.Token.IsCancellationRequested)
            {
                tickCount++;
                var tickStart = stopwatch.Elapsed;

                // 1. Drain incoming inputs from the actor channel for this tick
                var inputsToApply = new List<PlayerInput>();
                while (_inputChannel.Reader.TryRead(out var inputDto))
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

                // 2. Authoritative deterministic step in GameCore
                var tickResult = _simulation.Step(inputsToApply.ToArray());

                // Record into replay
                Replay.Ticks.Add(new TickInputBundle(tickCount, inputsToApply));
                if (tickCount % 30 == 0)
                {
                    Replay.CheckpointHashes[tickCount] = tickResult.WorldHash;
                }

                // 3. Broadcast snapshot to players at ~20Hz (2 out of 3 ticks: ticks % 3 != 0)
                if (tickCount % 3 != 0 || _simulation.State.IsMatchOver)
                {
                    var snapshot = CreateSnapshotDto(tickResult.Tick, tickResult.WorldHash, lastAckedSeq);
                    await _hubContext.Clients.Group(_matchId).SendAsync("WorldSnapshotReceived", snapshot, _cts.Token);
                }

                if (_simulation.State.IsMatchOver)
                {
                    Replay.FinalWorldHash = _simulation.State.ComputeHash();
                    Replay.TotalTicks = tickCount;
                    _logger.LogInformation("Match {MatchId} finished at tick {Tick}. Winner: {WinnerId}", _matchId, tickCount, _simulation.State.WinnerPlayerId);
                    break;
                }

                // 4. Drift compensation calculation (targetTime = start + tickCount * dt)
                var expectedElapsedMs = tickCount * MillisecondsPerTick;
                var currentElapsedMs = stopwatch.Elapsed.TotalMilliseconds;
                var sleepRemainingMs = expectedElapsedMs - currentElapsedMs;

                if (sleepRemainingMs > 1.0)
                {
                    await Task.Delay(TimeSpan.FromMilliseconds(sleepRemainingMs), _cts.Token);
                }
                else if (sleepRemainingMs < -50.0)
                {
                    _logger.LogWarning("Match {MatchId} simulation loop falling behind by {LagMs:F2}ms at tick {Tick}", _matchId, -sleepRemainingMs, tickCount);
                }
            }
        }
        catch (OperationCanceledException)
        {
            // Session cancellation requested
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
        _inputChannel.Writer.TryComplete();
    }
}

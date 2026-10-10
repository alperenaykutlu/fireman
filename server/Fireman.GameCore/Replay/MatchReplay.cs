using Fireman.GameCore.Model;
using Fireman.GameCore.Simulation;

namespace Fireman.GameCore.Replay;

/// <summary>
/// Immutable representation of all inputs executed in a specific simulation tick.
/// </summary>
public sealed record TickInputBundle(long Tick, IReadOnlyList<PlayerInput> Inputs);

/// <summary>
/// Complete deterministic replay recording for an authoritative match.
/// Contains initial seed, setup parameters, all inputs per tick, and verification hashes.
/// </summary>
public sealed class MatchReplay
{
    public Guid MatchId { get; init; } = Guid.NewGuid();
    public int InitialSeed { get; init; }
    public int PlayerCount { get; init; } = 4;
    public int MapWidth { get; init; } = 15;
    public int MapHeight { get; init; } = 13;
    public List<TickInputBundle> Ticks { get; init; } = new();
    public Dictionary<long, ulong> CheckpointHashes { get; init; } = new();
    public ulong FinalWorldHash { get; set; }
    public long TotalTicks { get; set; }
}

public sealed record ReplayValidationResult(
    bool IsSuccess,
    long DesyncTick = -1,
    ulong ExpectedHash = 0,
    ulong ActualHash = 0,
    string? ErrorMessage = null
);

/// <summary>
/// Bit-by-bit determinism replay validator. Re-executes recorded matches from scratch
/// and validates every checkpoint and final state hash.
/// </summary>
public static class ReplayValidator
{
    public static ReplayValidationResult Validate(MatchReplay replay)
    {
        if (replay == null)
            return new ReplayValidationResult(false, ErrorMessage: "Replay cannot be null");

        var simulation = new MatchSimulation(new MatchConfig
        {
            InitialSeed = replay.InitialSeed,
            PlayerCount = replay.PlayerCount,
            Columns = replay.MapWidth,
            Rows = replay.MapHeight
        });

        // Index tick inputs for O(1) lookup
        var inputMap = replay.Ticks.ToDictionary(t => t.Tick, t => t.Inputs);

        long maxTick = replay.TotalTicks > 0 ? replay.TotalTicks : (replay.Ticks.Count > 0 ? replay.Ticks.Max(t => t.Tick) : 0);

        for (long tick = 1; tick <= maxTick; tick++)
        {
            var inputs = inputMap.TryGetValue(tick, out var tickInputs)
                ? tickInputs.ToArray()
                : Array.Empty<PlayerInput>();

            var stepResult = simulation.Step(inputs);

            // Check if there is an expected hash for this tick
            if (replay.CheckpointHashes.TryGetValue(tick, out var expectedHash))
            {
                if (stepResult.WorldHash != expectedHash)
                {
                    return new ReplayValidationResult(
                        IsSuccess: false,
                        DesyncTick: tick,
                        ExpectedHash: expectedHash,
                        ActualHash: stepResult.WorldHash,
                        ErrorMessage: $"Desynchronization detected at tick {tick}! Expected hash {expectedHash:X16}, calculated {stepResult.WorldHash:X16}"
                    );
                }
            }

            if (simulation.State.IsMatchOver)
            {
                break;
            }
        }

        if (replay.FinalWorldHash != 0 && simulation.State.ComputeHash() != replay.FinalWorldHash)
        {
            return new ReplayValidationResult(
                IsSuccess: false,
                DesyncTick: maxTick,
                ExpectedHash: replay.FinalWorldHash,
                ActualHash: simulation.State.ComputeHash(),
                ErrorMessage: $"Final state hash mismatch! Expected {replay.FinalWorldHash:X16}, calculated {simulation.State.ComputeHash():X16}"
            );
        }

        return new ReplayValidationResult(IsSuccess: true);
    }
}

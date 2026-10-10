using Fireman.GameCore.Model;
using Fireman.GameCore.Replay;
using Fireman.GameCore.Simulation;
using Xunit;

namespace Fireman.UnitTests.GameCore;

public sealed class ReplayValidatorTests
{
    [Fact]
    public void Validate_BitByBitDeterministicReplay_Succeeds()
    {
        // Arrange
        const int seed = 424242;
        const int playerCount = 4;
        const int totalTicks = 200;

        var sim = new MatchSimulation(new MatchConfig
        {
            InitialSeed = seed,
            PlayerCount = playerCount
        });

        var replay = new MatchReplay
        {
            MatchId = Guid.NewGuid(),
            InitialSeed = seed,
            PlayerCount = playerCount,
            TotalTicks = totalTicks
        };

        // Record a match with simulated player movements
        for (long tick = 1; tick <= totalTicks; tick++)
        {
            var inputs = new List<PlayerInput>();

            if (tick % 10 == 0)
            {
                inputs.Add(new PlayerInput(1, tick, tick, Direction.Right, PlaceBomb: false));
                inputs.Add(new PlayerInput(2, tick, tick, Direction.Down, PlaceBomb: false));
            }
            if (tick == 50)
            {
                inputs.Add(new PlayerInput(1, tick, tick, Direction.None, PlaceBomb: true));
            }

            var stepResult = sim.Step(inputs.ToArray());

            replay.Ticks.Add(new TickInputBundle(tick, inputs));

            // Record checkpoint hashes every 25 ticks
            if (tick % 25 == 0)
            {
                replay.CheckpointHashes[tick] = stepResult.WorldHash;
            }

            if (sim.State.IsMatchOver)
            {
                replay.TotalTicks = tick;
                break;
            }
        }

        replay.FinalWorldHash = sim.State.ComputeHash();

        // Act
        var result = ReplayValidator.Validate(replay);

        // Assert
        Assert.True(result.IsSuccess, result.ErrorMessage);
        Assert.Equal(-1, result.DesyncTick);
    }

    [Fact]
    public void Validate_TamperedReplayInput_DetectsDesynchronization()
    {
        // Arrange
        const int seed = 999111;
        const int playerCount = 2;
        const int totalTicks = 100;

        var sim = new MatchSimulation(new MatchConfig
        {
            InitialSeed = seed,
            PlayerCount = playerCount
        });

        var replay = new MatchReplay
        {
            MatchId = Guid.NewGuid(),
            InitialSeed = seed,
            PlayerCount = playerCount,
            TotalTicks = totalTicks
        };

        for (long tick = 1; tick <= totalTicks; tick++)
        {
            var inputs = new List<PlayerInput>
            {
                new PlayerInput(1, tick, tick, Direction.Down, PlaceBomb: false)
            };

            var stepResult = sim.Step(inputs.ToArray());
            replay.Ticks.Add(new TickInputBundle(tick, inputs));
            replay.CheckpointHashes[tick] = stepResult.WorldHash;
        }

        replay.FinalWorldHash = sim.State.ComputeHash();

        // Tamper with tick 40 input (change Down to Left)
        var tamperedTickIndex = replay.Ticks.FindIndex(t => t.Tick == 40);
        replay.Ticks[tamperedTickIndex] = new TickInputBundle(40, new[]
        {
            new PlayerInput(1, 40, 40, Direction.Left, PlaceBomb: false)
        });

        // Act
        var result = ReplayValidator.Validate(replay);

        // Assert
        Assert.False(result.IsSuccess);
        Assert.True(result.DesyncTick >= 40, $"Expected desync >= 40, but was {result.DesyncTick}");
    }
}

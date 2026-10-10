using System.Diagnostics;
using Fireman.GameCore.Model;
using Fireman.GameCore.Randomness;
using Fireman.GameCore.Simulation;
using Xunit;

namespace Fireman.UnitTests.GameCore;

public class SimulationBenchmarkTests
{
    [Fact]
    public void TickBenchmark_SingleTickDuration_MustBeUnderOneMillisecond()
    {
        // Target: < 1.0 ms per tick for 4 players
        var config = new MatchConfig
        {
            InitialSeed = 42,
            PlayerCount = 4
        };
        var sim = new MatchSimulation(config, new SeededRandom(42));

        // Warmup (100 ticks)
        for (int i = 0; i < 100; i++)
        {
            sim.Step([
                new PlayerInput(1, i, i, Direction.Right, false),
                new PlayerInput(2, i, i, Direction.Down, false)
            ]);
        }

        // Measure 1,000 continuous ticks (~33.3 seconds of real-time match)
        var sw = Stopwatch.StartNew();
        const int benchmarkTicks = 1000;

        for (int tick = 0; tick < benchmarkTicks; tick++)
        {
            var inputs = new PlayerInput[]
            {
                new(1, tick, tick, (Direction)((tick % 4) + 1), tick % 30 == 0),
                new(2, tick, tick, (Direction)(((tick + 1) % 4) + 1), tick % 45 == 0),
                new(3, tick, tick, (Direction)(((tick + 2) % 4) + 1), tick % 50 == 0),
                new(4, tick, tick, (Direction)(((tick + 3) % 4) + 1), tick % 60 == 0)
            };

            sim.Step(inputs);
        }
        sw.Stop();

        double totalMs = sw.Elapsed.TotalMilliseconds;
        double avgMsPerTick = totalMs / benchmarkTicks;

        // Assert average tick time is well below the 1.0ms budget (and miles below 33.3ms budget)
        Assert.True(avgMsPerTick < 1.0, $"Avg tick duration was {avgMsPerTick:F3}ms, exceeding 1.0ms SLO limit.");
    }
}

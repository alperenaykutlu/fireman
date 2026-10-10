using Fireman.GameCore.Events;
using Fireman.GameCore.Model;
using Fireman.GameCore.Randomness;
using Fireman.GameCore.Simulation;
using Xunit;

namespace Fireman.UnitTests.GameCore;

public class MatchSimulationTests
{
    [Fact]
    public void Simulation_WithIdenticalSeedsAndInputs_ProducesIdenticalHash_DeterminismGoldenTest()
    {
        // Arrange
        const int seed = 98765;
        var config1 = new MatchConfig { InitialSeed = seed, PlayerCount = 4 };
        var config2 = new MatchConfig { InitialSeed = seed, PlayerCount = 4 };

        var sim1 = new MatchSimulation(config1, new SeededRandom(seed));
        var sim2 = new MatchSimulation(config2, new SeededRandom(seed));

        // Act: Run 120 ticks (~4 seconds of gameplay) with recorded inputs
        for (int tick = 0; tick < 120; tick++)
        {
            var inputs = new PlayerInput[]
            {
                new(PlayerId: 1, Seq: tick, Tick: tick, MoveDir: tick < 20 ? Direction.Right : Direction.Down, PlaceBomb: tick == 5),
                new(PlayerId: 2, Seq: tick, Tick: tick, MoveDir: tick < 15 ? Direction.Left : Direction.Up, PlaceBomb: tick == 10)
            };

            var res1 = sim1.Step(inputs);
            var res2 = sim2.Step(inputs);

            // Assert each tick hash is 100% bit-for-bit identical
            Assert.Equal(res1.WorldHash, res2.WorldHash);
            Assert.Equal(res1.Events.Count, res2.Events.Count);
        }
    }

    [Fact]
    public void WallCollision_PreventsPlayerFromMovingIntoPillars()
    {
        // Player 1 spawns at (0, 0). (1, 1) is a solid pillar.
        var sim = new MatchSimulation(new MatchConfig { InitialSeed = 42, PlayerCount = 1 });
        var initialPos = sim.State.Players[0].Position;

        // Try to move left beyond grid border
        for (int i = 0; i < 20; i++)
        {
            sim.Step([new PlayerInput(PlayerId: 1, Seq: i, Tick: i, MoveDir: Direction.Left, PlaceBomb: false)]);
        }

        // Must still be clamped at 0
        Assert.True(sim.State.Players[0].Position.RawX >= 0);
        Assert.Equal(0, sim.State.Players[0].Position.TileX);
    }

    [Fact]
    public void BombExplosion_DestroysBarrel_AndSpawnsFlame()
    {
        var config = new MatchConfig
        {
            InitialSeed = 111,
            PlayerCount = 1,
            FuseTicks = 5,
            FlameDurationTicks = 10,
            BarrelDropRatePercent = 100
        };
        var sim = new MatchSimulation(config, new SeededRandom(111));

        // Place a barrel right at (1, 0)
        sim.State.SetTile(1, 0, TileType.Barrel);

        // Player 1 places a bomb at (0, 0)
        sim.Step([new PlayerInput(PlayerId: 1, Seq: 1, Tick: 1, MoveDir: Direction.None, PlaceBomb: true)]);
        Assert.Single(sim.State.Bombs);

        // Advance 5 ticks so the bomb detonates
        for (int i = 0; i < 5; i++)
        {
            sim.Step([]);
        }

        // Bomb should have exploded, barrel destroyed (tile becomes Empty), flame present
        Assert.Empty(sim.State.Bombs);
        Assert.Equal(TileType.Empty, sim.State.GetTile(1, 0));
        Assert.Contains(sim.State.Flames, f => f.TileX == 1 && f.TileY == 0);
        Assert.Contains(sim.State.Flames, f => f.TileX == 0 && f.TileY == 0);
    }

    [Fact]
    public void ChainReaction_ExplodesAdjacentBombImmediately()
    {
        var config = new MatchConfig
        {
            InitialSeed = 222,
            PlayerCount = 2,
            FuseTicks = 60
        };
        var sim = new MatchSimulation(config);

        // Place bomb 1 at (0, 0) with 1 tick left
        sim.State.Bombs.Add(new BombState
        {
            Id = 101,
            OwnerPlayerId = 1,
            TileX = 0,
            TileY = 0,
            Range = 2,
            RemainingTicks = 1
        });

        // Place bomb 2 at (1, 0) with 50 ticks left
        sim.State.Bombs.Add(new BombState
        {
            Id = 102,
            OwnerPlayerId = 2,
            TileX = 1,
            TileY = 0,
            Range = 1,
            RemainingTicks = 50
        });

        // Step 1 tick -> Bomb 1 explodes and should trigger Bomb 2 via BFS chain reaction in the same tick
        var result = sim.Step([]);

        Assert.Empty(sim.State.Bombs);
        var explodedEvents = result.Events.Where(e => e.Type == SimEventType.BombExploded).ToList();
        Assert.Equal(2, explodedEvents.Count);
    }

    [Fact]
    public void PowerUp_IncreasesPlayerStatsWhenCollected()
    {
        var sim = new MatchSimulation(new MatchConfig { InitialSeed = 333, PlayerCount = 1 });
        var player = sim.State.Players[0];
        int initialCapacity = player.BombCapacity;

        // Place a bomb powerup at player's current tile (0, 0)
        sim.State.PowerUps.Add(new PowerUpState
        {
            Id = 999,
            TileX = 0,
            TileY = 0,
            Type = PowerUpType.Bomb
        });

        // Step simulation
        sim.Step([]);

        // Player collected powerup -> capacity increased and powerup removed
        Assert.Equal(initialCapacity + 1, player.BombCapacity);
        Assert.Empty(sim.State.PowerUps);
    }
}

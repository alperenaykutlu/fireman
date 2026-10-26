namespace Fireman.GameCore.Model;

public enum TileType : byte
{
    Empty = 0,
    Wall = 1,      // Indestructible pillar
    Barrel = 2     // Destructible barrel
}

public enum Direction : byte
{
    None = 0,
    Up = 1,
    Down = 2,
    Left = 3,
    Right = 4
}

public enum PowerUpType : byte
{
    None = 0,
    Lightning = 1, // Range +1
    Shoe = 2,      // Speed +1
    Bomb = 3,      // Bomb capacity +1
    Heal = 4       // Health +1
}

public readonly record struct FixedPos(int RawX, int RawY)
{
    // Fixed point factor: 256 sub-units = 1 full tile
    public const int SubUnitsPerTile = 256;

    public int TileX => RawX / SubUnitsPerTile;
    public int TileY => RawY / SubUnitsPerTile;

    public static FixedPos FromTile(int tileX, int tileY) =>
        new(tileX * SubUnitsPerTile + SubUnitsPerTile / 2, tileY * SubUnitsPerTile + SubUnitsPerTile / 2);

    public static FixedPos FromSubUnits(int subX, int subY) =>
        new(subX, subY);
}

public sealed class PlayerState
{
    public int Id { get; init; }
    public string Name { get; set; } = string.Empty;
    public FixedPos Position { get; set; }
    public int MoveSpeedSubUnitsPerTick { get; set; } = 8; // Default ~1 tile per second at 30 ticks/s
    public int Health { get; set; } = 1;
    public int Score { get; set; }
    public int BombCapacity { get; set; } = 1;
    public int BombRange { get; set; } = 1;
    public int ActiveBombs { get; set; }
    public bool IsAlive { get; set; } = true;
    public long LastProcessedSeq { get; set; }
}

public sealed class BombState
{
    public int Id { get; init; }
    public int OwnerPlayerId { get; init; }
    public int TileX { get; init; }
    public int TileY { get; init; }
    public int Range { get; init; }
    public int RemainingTicks { get; set; } // ~66 ticks (2.2s at 30Hz)
}

public sealed class FlameTile
{
    public int TileX { get; init; }
    public int TileY { get; init; }
    public int RemainingTicks { get; set; } // ~15 ticks (0.5s)
    public int OwnerPlayerId { get; init; }
    public HashSet<int> DamagedPlayerIds { get; } = [];
}

public sealed class PowerUpState
{
    public int Id { get; init; }
    public int TileX { get; init; }
    public int TileY { get; init; }
    public PowerUpType Type { get; init; }
}

public readonly record struct PlayerInput(
    int PlayerId,
    long Seq,
    long Tick,
    Direction MoveDir,
    bool PlaceBomb
);

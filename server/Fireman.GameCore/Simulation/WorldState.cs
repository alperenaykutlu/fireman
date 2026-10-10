using Fireman.GameCore.Events;
using Fireman.GameCore.Model;

namespace Fireman.GameCore.Simulation;

public sealed class WorldState
{
    public const int Columns = 11;
    public const int Rows = 9;

    public long Tick { get; set; }
    public TileType[] Tiles { get; } = new TileType[Columns * Rows];
    public List<PlayerState> Players { get; } = new();
    public List<BombState> Bombs { get; } = new();
    public List<FlameTile> Flames { get; } = new();
    public List<PowerUpState> PowerUps { get; } = new();
    public bool IsMatchOver { get; set; }
    public int? WinnerPlayerId { get; set; }

    public TileType GetTile(int x, int y)
    {
        if (x < 0 || x >= Columns || y < 0 || y >= Rows) return TileType.Wall;
        return Tiles[y * Columns + x];
    }

    public void SetTile(int x, int y, TileType type)
    {
        if (x >= 0 && x < Columns && y >= 0 && y < Rows)
        {
            Tiles[y * Columns + x] = type;
        }
    }

    public ulong ComputeHash()
    {
        // FNV-1a 64-bit hash for deterministic bit-level verification
        ulong hash = 14695981039346656037UL;
        const ulong prime = 1099511628211UL;

        // Hash tick
        hash = (hash ^ (ulong)Tick) * prime;

        // Hash tiles
        for (int i = 0; i < Tiles.Length; i++)
        {
            hash = (hash ^ (byte)Tiles[i]) * prime;
        }

        // Hash players (sorted by ID)
        foreach (var p in Players.OrderBy(p => p.Id))
        {
            hash = (hash ^ (ulong)p.Id) * prime;
            hash = (hash ^ (ulong)p.Position.RawX) * prime;
            hash = (hash ^ (ulong)p.Position.RawY) * prime;
            hash = (hash ^ (ulong)p.Health) * prime;
            hash = (hash ^ (ulong)p.BombCapacity) * prime;
            hash = (hash ^ (ulong)p.BombRange) * prime;
            hash = (hash ^ (ulong)(p.IsAlive ? 1UL : 0UL)) * prime;
        }

        // Hash bombs
        foreach (var b in Bombs.OrderBy(b => b.Id))
        {
            hash = (hash ^ (ulong)b.Id) * prime;
            hash = (hash ^ (ulong)b.TileX) * prime;
            hash = (hash ^ (ulong)b.TileY) * prime;
            hash = (hash ^ (ulong)b.RemainingTicks) * prime;
        }

        // Hash flames
        foreach (var f in Flames.OrderBy(f => f.TileY * Columns + f.TileX))
        {
            hash = (hash ^ (ulong)f.TileX) * prime;
            hash = (hash ^ (ulong)f.TileY) * prime;
            hash = (hash ^ (ulong)f.RemainingTicks) * prime;
        }

        // Hash powerups
        foreach (var p in PowerUps.OrderBy(p => p.Id))
        {
            hash = (hash ^ (ulong)p.Id) * prime;
            hash = (hash ^ (ulong)p.TileX) * prime;
            hash = (hash ^ (ulong)p.TileY) * prime;
            hash = (hash ^ (byte)p.Type) * prime;
        }

        return hash;
    }
}

public readonly record struct TickResult(
    long Tick,
    ulong WorldHash,
    IReadOnlyList<SimEvent> Events
);

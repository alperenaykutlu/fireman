using Fireman.GameCore.Model;

namespace Fireman.GameCore.Events;

public enum SimEventType : byte
{
    BombPlaced = 1,
    BombExploded = 2,
    BarrelDestroyed = 3,
    PowerUpSpawned = 4,
    PowerUpCollected = 5,
    PlayerDamaged = 6,
    PlayerDied = 7,
    MatchEnded = 8
}

public readonly record struct SimEvent(
    SimEventType Type,
    int SourceId,
    int TileX,
    int TileY,
    int Value = 0
);

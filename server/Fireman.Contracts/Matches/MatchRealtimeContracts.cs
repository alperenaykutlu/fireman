namespace Fireman.Contracts.Matches;

/// <summary>
/// Client input packet sent every tick (30Hz) with sequence numbering.
/// </summary>
public record PlayerInputDto(
    Guid MatchId,
    Guid UserId,
    long Seq,
    long ClientTick,
    byte MoveDir,     // 0: None, 1: Up, 2: Down, 3: Left, 4: Right
    bool PlaceBomb,
    int SubTileX,     // Client's predicted sub-tile position (256 units = 1 tile)
    int SubTileY
);

/// <summary>
/// Server authoritative world state broadcast sent at 15-20Hz to clients.
/// </summary>
public record WorldSnapshotDto(
    Guid MatchId,
    long Tick,
    ulong WorldHash,
    long LastAckedSeq,
    List<PlayerSnapshotDto> Players,
    List<BombSnapshotDto> Bombs,
    List<FlameSnapshotDto> Flames,
    List<PowerUpSnapshotDto> PowerUps,
    bool IsMatchOver,
    int? WinnerId
);

public record PlayerSnapshotDto(
    int PlayerId,
    Guid UserId,
    int SubTileX,
    int SubTileY,
    int Health,
    int BombCapacity,
    int BombRange,
    int Speed,
    bool IsAlive
);

public record BombSnapshotDto(
    int BombId,
    int TileX,
    int TileY,
    int RemainingTicks,
    int Range
);

public record FlameSnapshotDto(
    int TileX,
    int TileY,
    int RemainingTicks
);

public record PowerUpSnapshotDto(
    int Id,
    int TileX,
    int TileY,
    byte Type
);

public record MatchChatMessageDto(
    Guid UserId,
    string Username,
    string Message,
    DateTime Timestamp
);

public record MatchLobbyUpdateDto(
    Guid MatchId,
    List<Guid> ReadyPlayerIds,
    bool AllPlayersReady
);

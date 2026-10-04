namespace Fireman.Contracts.Matches;

public record PlayerMovementDto(
    Guid UserId,
    float PosX,
    float PosY,
    float PosZ,
    float RotationY,
    float Velocity
);

public record FireSuppressionActionDto(
    Guid UserId,
    Guid FireInstanceId,
    float WaterVolume,
    bool Extinguished
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

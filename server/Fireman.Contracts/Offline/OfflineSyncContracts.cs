namespace Fireman.Contracts.Offline;

public record OfflineActionDto(
    Guid ActionId,
    string ActionType, // e.g. "CompleteMission", "CollectCoins"
    string PayloadJson,
    DateTime ClientTimestamp,
    string ClientHash
);

public record OfflineSyncRequest(
    Guid BatchId,
    List<OfflineActionDto> Actions
);

public record OfflineActionResultDto(
    Guid ActionId,
    bool Accepted,
    string? ErrorReason,
    object? ServerData
);

public record OfflineSyncResponse(
    Guid BatchId,
    bool AllAccepted,
    int TotalProcessed,
    int AcceptedCount,
    int RejectedCount,
    List<OfflineActionResultDto> Results
);

using Fireman.Shared.Enums;

namespace Fireman.Contracts.Missions;

public record MissionDto(
    Guid Id,
    string Title,
    string Description,
    MissionType Type,
    int RequiredLevel,
    int BaseRewardCoins,
    int BaseRewardXp,
    int TargetScore
);

public record UserMissionDto(
    Guid Id,
    Guid MissionId,
    string Title,
    MissionType Type,
    MissionStatus Status,
    int CurrentScore,
    int TargetScore,
    DateTime? StartedAt,
    DateTime? CompletedAt
);

public record StartMissionRequest(Guid MissionId);

public record CompleteMissionRequest(
    Guid MissionId,
    int FinalScore,
    int RescuesCompleted,
    int DurationSeconds
);

public record MissionCompletionResultDto(
    bool Success,
    Guid MissionId,
    int EarnedCoins,
    int EarnedXp,
    bool LeveledUp,
    int NewLevel,
    string Message
);

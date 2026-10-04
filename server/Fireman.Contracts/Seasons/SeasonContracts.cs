using Fireman.Shared.Enums;

namespace Fireman.Contracts.Seasons;

public record SeasonRewardTierDto(
    int TierNumber,
    int RequiredPoints,
    RewardType RewardType,
    int Amount,
    Guid? ItemDefinitionId
);

public record SeasonDto(
    Guid Id,
    int SeasonNumber,
    string Title,
    DateTime StartDate,
    DateTime EndDate,
    bool IsActive,
    IReadOnlyList<SeasonRewardTierDto> RewardTiers
);

public record UserSeasonProgressDto(
    Guid SeasonId,
    int CurrentPoints,
    IReadOnlyList<int> ClaimedTiers
);

public record ClaimSeasonTierRequest(Guid SeasonId, int TierNumber);

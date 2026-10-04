using Fireman.Domain.Common;
using Fireman.Shared.Enums;
using Fireman.Shared.Exceptions;

namespace Fireman.Domain.Seasons;

public class SeasonRewardTier : Entity<Guid>
{
    public Guid SeasonId { get; private set; }
    public int TierNumber { get; private set; }
    public int RequiredPoints { get; private set; }
    public RewardType RewardType { get; private set; }
    public int Amount { get; private set; }
    public Guid? ItemDefinitionId { get; private set; }

    public SeasonRewardTier(
        Guid seasonId,
        int tierNumber,
        int requiredPoints,
        RewardType rewardType,
        int amount,
        Guid? itemDefinitionId = null)
    {
        Id = Guid.NewGuid();
        SeasonId = seasonId;
        TierNumber = tierNumber;
        RequiredPoints = requiredPoints;
        RewardType = rewardType;
        Amount = amount;
        ItemDefinitionId = itemDefinitionId;
        CreatedAt = DateTime.UtcNow;
    }
}

public class Season : AggregateRoot<Guid>
{
    private readonly List<SeasonRewardTier> _rewardTiers = new();

    public int SeasonNumber { get; private set; }
    public string Title { get; private set; } = string.Empty;
    public DateTime StartDate { get; private set; }
    public DateTime EndDate { get; private set; }
    public bool IsActive => DateTime.UtcNow >= StartDate && DateTime.UtcNow <= EndDate;
    public IReadOnlyCollection<SeasonRewardTier> RewardTiers => _rewardTiers.AsReadOnly();

    private Season() { }

    public static Season Create(int seasonNumber, string title, DateTime startDate, DateTime endDate)
    {
        if (endDate <= startDate)
            throw new ValidationException("End date must be after start date.");

        var season = new Season
        {
            Id = Guid.NewGuid(),
            SeasonNumber = seasonNumber,
            Title = title.Trim(),
            StartDate = startDate,
            EndDate = endDate,
            CreatedAt = DateTime.UtcNow
        };

        return season;
    }

    public void AddRewardTier(int tierNumber, int requiredPoints, RewardType rewardType, int amount, Guid? itemDefinitionId = null)
    {
        _rewardTiers.Add(new SeasonRewardTier(Id, tierNumber, requiredPoints, rewardType, amount, itemDefinitionId));
    }
}

public class UserSeasonProgress : AggregateRoot<Guid>
{
    private readonly HashSet<int> _claimedTiers = new();

    public Guid UserId { get; private set; }
    public Guid SeasonId { get; private set; }
    public int CurrentPoints { get; private set; }
    public IReadOnlyCollection<int> ClaimedTiers => _claimedTiers;

    private UserSeasonProgress() { }

    public static UserSeasonProgress Create(Guid userId, Guid seasonId)
    {
        return new UserSeasonProgress
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            SeasonId = seasonId,
            CurrentPoints = 0,
            CreatedAt = DateTime.UtcNow
        };
    }

    public void AddPoints(int points)
    {
        if (points <= 0) return;
        CurrentPoints += points;
        UpdatedAt = DateTime.UtcNow;
    }

    public bool CanClaimTier(SeasonRewardTier tier)
    {
        return CurrentPoints >= tier.RequiredPoints && !_claimedTiers.Contains(tier.TierNumber);
    }

    public void ClaimTier(SeasonRewardTier tier)
    {
        if (!CanClaimTier(tier))
            throw new DomainException($"Cannot claim tier {tier.TierNumber}. Insufficient points or already claimed.");

        _claimedTiers.Add(tier.TierNumber);
        UpdatedAt = DateTime.UtcNow;
    }
}

public interface ISeasonRepository
{
    Task<Season?> GetCurrentActiveSeasonAsync(CancellationToken cancellationToken = default);
    Task<Season?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<UserSeasonProgress?> GetUserProgressAsync(Guid userId, Guid seasonId, CancellationToken cancellationToken = default);
    Task AddSeasonAsync(Season season, CancellationToken cancellationToken = default);
    Task AddUserProgressAsync(UserSeasonProgress progress, CancellationToken cancellationToken = default);
    Task UpdateUserProgressAsync(UserSeasonProgress progress, CancellationToken cancellationToken = default);
}

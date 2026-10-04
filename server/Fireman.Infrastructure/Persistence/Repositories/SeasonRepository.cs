using Fireman.Domain.Seasons;

namespace Fireman.Infrastructure.Persistence.Repositories;

public class SeasonRepository : ISeasonRepository
{
    private readonly List<Season> _seasons = new();
    private readonly List<UserSeasonProgress> _progresses = new();

    public SeasonRepository()
    {
        // Seed default Season 1: Inferno Dawn
        var season1 = Season.Create(
            1,
            "Season 1: Inferno Dawn",
            DateTime.UtcNow.AddDays(-5),
            DateTime.UtcNow.AddDays(25));

        season1.AddRewardTier(1, 100, Shared.Enums.RewardType.Coins, 250);
        season1.AddRewardTier(2, 300, Shared.Enums.RewardType.Gems, 15);
        season1.AddRewardTier(3, 600, Shared.Enums.RewardType.Coins, 750);
        season1.AddRewardTier(4, 1000, Shared.Enums.RewardType.Gems, 30);

        _seasons.Add(season1);
    }

    public Task<Season?> GetCurrentActiveSeasonAsync(CancellationToken cancellationToken = default)
    {
        lock (_seasons)
        {
            var now = DateTime.UtcNow;
            var current = _seasons.FirstOrDefault(s => s.StartDate <= now && s.EndDate >= now);
            return Task.FromResult(current);
        }
    }

    public Task<Season?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        lock (_seasons)
        {
            return Task.FromResult(_seasons.FirstOrDefault(s => s.Id == id));
        }
    }

    public Task<UserSeasonProgress?> GetUserProgressAsync(Guid userId, Guid seasonId, CancellationToken cancellationToken = default)
    {
        lock (_progresses)
        {
            return Task.FromResult(_progresses.FirstOrDefault(p => p.UserId == userId && p.SeasonId == seasonId));
        }
    }

    public Task AddSeasonAsync(Season season, CancellationToken cancellationToken = default)
    {
        lock (_seasons)
        {
            _seasons.Add(season);
        }
        return Task.CompletedTask;
    }

    public Task AddUserProgressAsync(UserSeasonProgress progress, CancellationToken cancellationToken = default)
    {
        lock (_progresses)
        {
            _progresses.Add(progress);
        }
        return Task.CompletedTask;
    }

    public Task UpdateUserProgressAsync(UserSeasonProgress progress, CancellationToken cancellationToken = default)
    {
        return Task.CompletedTask;
    }
}

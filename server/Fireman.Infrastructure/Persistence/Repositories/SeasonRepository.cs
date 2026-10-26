using Fireman.Application.Common.Interfaces;
using Fireman.Domain.Seasons;
using Fireman.Shared.Enums;

namespace Fireman.Infrastructure.Persistence.Repositories;

public sealed class SeasonRepository(IDocumentDatabase database) : ISeasonRepository
{
    private const string Seasons = "seasons";
    private const string Progress = "seasonProgress";

    public async Task<Season?> GetCurrentActiveSeasonAsync(CancellationToken cancellationToken = default)
    {
        var seasons = await database.GetAllAsync<Season>(Seasons, cancellationToken);
        var current = seasons.FirstOrDefault(season => season.IsActive);
        if (current is not null) return current;
        if (seasons.Count != 0) return null;

        var seed = Season.Create(1, "Season 1: Inferno Dawn", DateTime.UtcNow.AddDays(-5), DateTime.UtcNow.AddDays(25));
        seed.AddRewardTier(1, 100, RewardType.Coins, 250);
        seed.AddRewardTier(2, 300, RewardType.Gems, 15);
        seed.AddRewardTier(3, 600, RewardType.Coins, 750);
        seed.AddRewardTier(4, 1000, RewardType.Gems, 30);
        await database.SetAsync(Seasons, seed.Id.ToString(), seed, cancellationToken);
        return seed;
    }

    public Task<Season?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) => database.GetAsync<Season>(Seasons, id.ToString(), cancellationToken);

    public async Task<UserSeasonProgress?> GetUserProgressAsync(Guid userId, Guid seasonId, CancellationToken cancellationToken = default) =>
        (await database.FindAsync<UserSeasonProgress>(Progress, new Dictionary<string, string> { ["userId"] = userId.ToString(), ["seasonId"] = seasonId.ToString() }, cancellationToken)).FirstOrDefault();

    public Task AddSeasonAsync(Season season, CancellationToken cancellationToken = default) => database.SetAsync(Seasons, season.Id.ToString(), season, cancellationToken);
    public Task AddUserProgressAsync(UserSeasonProgress progress, CancellationToken cancellationToken = default) => database.SetAsync(Progress, progress.Id.ToString(), progress, cancellationToken);
    public Task UpdateUserProgressAsync(UserSeasonProgress progress, CancellationToken cancellationToken = default) => database.SetAsync(Progress, progress.Id.ToString(), progress, cancellationToken);
}

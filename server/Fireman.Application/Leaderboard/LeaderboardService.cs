using Fireman.Application.Common.Interfaces;
using Fireman.Contracts.Leaderboard;
using Fireman.Domain.Characters;
using Fireman.Domain.Users;
using Fireman.Shared.Constants;
using Fireman.Shared.Results;

namespace Fireman.Application.Leaderboard;

public interface ILeaderboardService
{
    Task<Result<IReadOnlyList<LeaderboardEntryDto>>> GetGlobalLeaderboardAsync(CancellationToken cancellationToken = default);
}

public class LeaderboardService : ILeaderboardService
{
    private readonly ICacheService _cacheService;
    private readonly ICharacterRepository _characterRepository;
    private readonly IUserRepository _userRepository;

    public LeaderboardService(
        ICacheService cacheService,
        ICharacterRepository characterRepository,
        IUserRepository userRepository)
    {
        _cacheService = cacheService;
        _characterRepository = characterRepository;
        _userRepository = userRepository;
    }

    public async Task<Result<IReadOnlyList<LeaderboardEntryDto>>> GetGlobalLeaderboardAsync(CancellationToken cancellationToken = default)
    {
        // Try read from cache first
        var cached = await _cacheService.GetAsync<List<LeaderboardEntryDto>>(CacheKeys.LeaderboardGlobal, cancellationToken);
        if (cached is not null)
            return Result.Success<IReadOnlyList<LeaderboardEntryDto>>(cached);

        // Mock/compute initial entries
        var entries = new List<LeaderboardEntryDto>
        {
            new(1, Guid.NewGuid(), "FireHero99", 15400, 42, DateTime.UtcNow),
            new(2, Guid.NewGuid(), "SmokeJumper", 13200, 36, DateTime.UtcNow),
            new(3, Guid.NewGuid(), "ChiefRescue", 11800, 31, DateTime.UtcNow)
        };

        await _cacheService.SetAsync(CacheKeys.LeaderboardGlobal, entries, TimeSpan.FromMinutes(5), cancellationToken);

        return Result.Success<IReadOnlyList<LeaderboardEntryDto>>(entries);
    }
}

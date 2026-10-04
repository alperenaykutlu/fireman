using Fireman.Application.Common.Interfaces;
using Fireman.Shared.Constants;
using Microsoft.Extensions.Logging;

namespace Fireman.Application.Events.Handlers;

public class CharacterCacheInvalidationHandler : IEventHandler<ItemEquippedEvent>
{
    private readonly ICacheService _cacheService;
    private readonly ILogger<CharacterCacheInvalidationHandler> _logger;

    public CharacterCacheInvalidationHandler(
        ICacheService cacheService,
        ILogger<CharacterCacheInvalidationHandler> logger)
    {
        _cacheService = cacheService;
        _logger = logger;
    }

    public async Task HandleAsync(ItemEquippedEvent domainEvent, CancellationToken cancellationToken = default)
    {
        var cacheKey = CacheKeys.Character(domainEvent.CharacterId);
        _logger.LogInformation("CacheInvalidation: Invalidating character cache key {Key} after EquipItem.", cacheKey);
        await _cacheService.RemoveAsync(cacheKey, cancellationToken);
    }
}

public class LeaderboardCacheInvalidationHandler : IEventHandler<MissionCompletedEvent>, IEventHandler<MatchFinishedEvent>
{
    private readonly ICacheService _cacheService;
    private readonly ILogger<LeaderboardCacheInvalidationHandler> _logger;

    public LeaderboardCacheInvalidationHandler(
        ICacheService cacheService,
        ILogger<LeaderboardCacheInvalidationHandler> logger)
    {
        _cacheService = cacheService;
        _logger = logger;
    }

    public async Task HandleAsync(MissionCompletedEvent domainEvent, CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("CacheInvalidation: Invalidating global leaderboard cache key {Key} after MissionCompleted.",
            CacheKeys.LeaderboardGlobal);
        await _cacheService.RemoveAsync(CacheKeys.LeaderboardGlobal, cancellationToken);
    }

    public async Task HandleAsync(MatchFinishedEvent domainEvent, CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("CacheInvalidation: Invalidating global leaderboard cache key {Key} after MatchFinished.",
            CacheKeys.LeaderboardGlobal);
        await _cacheService.RemoveAsync(CacheKeys.LeaderboardGlobal, cancellationToken);
    }
}

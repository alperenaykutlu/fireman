using Microsoft.Extensions.Logging;

namespace Fireman.Application.Events.Handlers;

public class RewardEventHandler : IEventHandler<MissionCompletedEvent>
{
    private readonly ILogger<RewardEventHandler> _logger;

    public RewardEventHandler(ILogger<RewardEventHandler> logger)
    {
        _logger = logger;
    }

    public Task HandleAsync(MissionCompletedEvent domainEvent, CancellationToken cancellationToken = default)
    {
        _logger.LogInformation(
            "RewardHandler: Credited {Coins} coins and {Xp} XP to user {UserId} for mission {MissionId}",
            domainEvent.EarnedCoins, domainEvent.EarnedXp, domainEvent.UserId, domainEvent.MissionId);

        return Task.CompletedTask;
    }
}

public class AchievementEventHandler : IEventHandler<MissionCompletedEvent>
{
    private readonly ILogger<AchievementEventHandler> _logger;

    public AchievementEventHandler(ILogger<AchievementEventHandler> logger)
    {
        _logger = logger;
    }

    public Task HandleAsync(MissionCompletedEvent domainEvent, CancellationToken cancellationToken = default)
    {
        if (domainEvent.Rescues >= 5)
        {
            _logger.LogInformation("AchievementHandler: Unlocked 'Master Firefighter' for user {UserId}", domainEvent.UserId);
        }

        return Task.CompletedTask;
    }
}

public class AnalyticsEventHandler : IEventHandler<MissionCompletedEvent>, IEventHandler<ItemPurchasedEvent>
{
    private readonly ILogger<AnalyticsEventHandler> _logger;

    public AnalyticsEventHandler(ILogger<AnalyticsEventHandler> logger)
    {
        _logger = logger;
    }

    public Task HandleAsync(MissionCompletedEvent domainEvent, CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Analytics: Mission {MissionId} completed with score {Score} by user {UserId}",
            domainEvent.MissionId, domainEvent.Score, domainEvent.UserId);
        return Task.CompletedTask;
    }

    public Task HandleAsync(ItemPurchasedEvent domainEvent, CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Analytics: Item {ItemId} purchased by user {UserId} for {Price}",
            domainEvent.ItemDefinitionId, domainEvent.UserId, domainEvent.Price);
        return Task.CompletedTask;
    }
}

public class NotificationEventHandler : IEventHandler<MissionCompletedEvent>
{
    private readonly ILogger<NotificationEventHandler> _logger;

    public NotificationEventHandler(ILogger<NotificationEventHandler> logger)
    {
        _logger = logger;
    }

    public Task HandleAsync(MissionCompletedEvent domainEvent, CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Notification: Push notification sent to user {UserId}: 'Mission completed successfully!'",
            domainEvent.UserId);
        return Task.CompletedTask;
    }
}

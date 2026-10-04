using Fireman.Domain.Common;

namespace Fireman.Application.Events;

public interface IEventBus
{
    Task PublishAsync<TEvent>(TEvent domainEvent, CancellationToken cancellationToken = default) where TEvent : IDomainEvent;
}

public interface IEventHandler<in TEvent> where TEvent : IDomainEvent
{
    Task HandleAsync(TEvent domainEvent, CancellationToken cancellationToken = default);
}

public record MissionCompletedEvent(
    Guid UserId,
    Guid MissionId,
    int Score,
    int Rescues,
    int EarnedCoins,
    int EarnedXp
) : IDomainEvent;

public record ItemPurchasedEvent(
    Guid UserId,
    Guid ItemDefinitionId,
    int Price,
    int Quantity
) : IDomainEvent;

public record MatchFinishedEvent(
    Guid MatchId,
    Guid WinnerUserId,
    int FinalScore
) : IDomainEvent;

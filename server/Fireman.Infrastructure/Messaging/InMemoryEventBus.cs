using Fireman.Application.Events;
using Fireman.Domain.Common;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace Fireman.Infrastructure.Messaging;

public class InMemoryEventBus : IEventBus
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<InMemoryEventBus> _logger;

    public InMemoryEventBus(IServiceProvider serviceProvider, ILogger<InMemoryEventBus> logger)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
    }

    public async Task PublishAsync<TEvent>(TEvent domainEvent, CancellationToken cancellationToken = default)
        where TEvent : IDomainEvent
    {
        using var scope = _serviceProvider.CreateScope();
        var handlerType = typeof(IEventHandler<>).MakeGenericType(domainEvent.GetType());
        var handlers = scope.ServiceProvider.GetServices(handlerType);

        foreach (var handler in handlers)
        {
            try
            {
                var method = handlerType.GetMethod(nameof(IEventHandler<TEvent>.HandleAsync));
                if (method != null)
                {
                    var task = (Task)method.Invoke(handler, new object[] { domainEvent, cancellationToken })!;
                    await task;
                }
            }
            catch (Exception ex)
            {
                // Event Handler Isolation: Exception in one handler must NOT break others (Section 72)
                _logger.LogError(ex, "Error occurred executing event handler {HandlerType} for event {EventType}",
                    handler?.GetType().Name, typeof(TEvent).Name);
            }
        }
    }
}

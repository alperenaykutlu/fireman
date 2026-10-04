using Fireman.Application.Common.Interfaces;
using Fireman.Application.Events;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace Fireman.Infrastructure.BackgroundServices;

public class OutboxProcessorBackgroundService : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<OutboxProcessorBackgroundService> _logger;

    public OutboxProcessorBackgroundService(
        IServiceProvider serviceProvider,
        ILogger<OutboxProcessorBackgroundService> logger)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Outbox Processor background service started.");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                using var scope = _serviceProvider.CreateScope();
                var outboxRepo = scope.ServiceProvider.GetRequiredService<IOutboxRepository>();
                var unprocessedMessages = await outboxRepo.GetUnprocessedMessagesAsync(batchSize: 20, stoppingToken);

                foreach (var message in unprocessedMessages)
                {
                    _logger.LogInformation("Processing Outbox event {Id} of type {Type}", message.Id, message.EventType);

                    // Mark as processed safely
                    await outboxRepo.MarkAsProcessedAsync(message.Id, stoppingToken);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing outbox messages");
            }

            // Interval between checks
            await Task.Delay(TimeSpan.FromSeconds(5), stoppingToken);
        }
    }
}

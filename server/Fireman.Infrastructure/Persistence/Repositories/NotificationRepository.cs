using Fireman.Domain.Notifications;

namespace Fireman.Infrastructure.Persistence.Repositories;

public class NotificationRepository : INotificationRepository
{
    private readonly List<InAppNotification> _notifications = new();

    public Task<IReadOnlyList<InAppNotification>> GetUserNotificationsAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        lock (_notifications)
        {
            var list = _notifications.Where(n => n.UserId == userId).OrderByDescending(n => n.CreatedAt).ToList();
            return Task.FromResult<IReadOnlyList<InAppNotification>>(list);
        }
    }

    public Task<InAppNotification?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        lock (_notifications)
        {
            return Task.FromResult(_notifications.FirstOrDefault(n => n.Id == id));
        }
    }

    public Task AddAsync(InAppNotification notification, CancellationToken cancellationToken = default)
    {
        lock (_notifications)
        {
            _notifications.Add(notification);
        }
        return Task.CompletedTask;
    }

    public Task UpdateAsync(InAppNotification notification, CancellationToken cancellationToken = default)
    {
        return Task.CompletedTask;
    }
}

using Fireman.Domain.Common;
using Fireman.Shared.Enums;

namespace Fireman.Domain.Notifications;

public class InAppNotification : Entity<Guid>
{
    public Guid UserId { get; private set; }
    public string Title { get; private set; }
    public string Message { get; private set; }
    public NotificationType Type { get; private set; }
    public bool IsRead { get; private set; }

    public InAppNotification(
        Guid userId,
        string title,
        string message,
        NotificationType type)
    {
        Id = Guid.NewGuid();
        UserId = userId;
        Title = title;
        Message = message;
        Type = type;
        IsRead = false;
        CreatedAt = DateTime.UtcNow;
    }

    public void MarkAsRead()
    {
        IsRead = true;
        UpdatedAt = DateTime.UtcNow;
    }
}

public interface INotificationRepository
{
    Task<IReadOnlyList<InAppNotification>> GetUserNotificationsAsync(Guid userId, CancellationToken cancellationToken = default);
    Task<InAppNotification?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task AddAsync(InAppNotification notification, CancellationToken cancellationToken = default);
    Task UpdateAsync(InAppNotification notification, CancellationToken cancellationToken = default);
}

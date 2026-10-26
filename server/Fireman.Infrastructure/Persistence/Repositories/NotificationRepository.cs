using Fireman.Application.Common.Interfaces;
using Fireman.Domain.Notifications;

namespace Fireman.Infrastructure.Persistence.Repositories;

public sealed class NotificationRepository(IDocumentDatabase database) : INotificationRepository
{
    private const string Collection = "notifications";
    public async Task<IReadOnlyList<InAppNotification>> GetUserNotificationsAsync(Guid userId, CancellationToken cancellationToken = default) =>
        (await database.FindAsync<InAppNotification>(Collection, new Dictionary<string, string> { ["userId"] = userId.ToString() }, cancellationToken)).OrderByDescending(n => n.CreatedAt).ToList();
    public Task<InAppNotification?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) => database.GetAsync<InAppNotification>(Collection, id.ToString(), cancellationToken);
    public Task AddAsync(InAppNotification notification, CancellationToken cancellationToken = default) => database.SetAsync(Collection, notification.Id.ToString(), notification, cancellationToken);
    public Task UpdateAsync(InAppNotification notification, CancellationToken cancellationToken = default) => database.SetAsync(Collection, notification.Id.ToString(), notification, cancellationToken);
}

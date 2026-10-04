using Fireman.Application.Common.Interfaces;
using Fireman.Contracts.Notifications;
using Fireman.Domain.Notifications;
using Fireman.Shared.Enums;
using Fireman.Shared.Results;

namespace Fireman.Application.Notifications;

public interface INotificationService
{
    Task<Result<IReadOnlyList<NotificationDto>>> GetUserNotificationsAsync(CancellationToken cancellationToken = default);
    Task<Result<bool>> MarkAsReadAsync(Guid notificationId, CancellationToken cancellationToken = default);
    Task<Result<bool>> SendNotificationAsync(Guid userId, string title, string message, NotificationType type, CancellationToken cancellationToken = default);
}

public class NotificationService : INotificationService
{
    private readonly INotificationRepository _notificationRepository;
    private readonly ICurrentUser _currentUser;
    private readonly IUnitOfWork _unitOfWork;

    public NotificationService(
        INotificationRepository notificationRepository,
        ICurrentUser currentUser,
        IUnitOfWork unitOfWork)
    {
        _notificationRepository = notificationRepository;
        _currentUser = currentUser;
        _unitOfWork = unitOfWork;
    }

    public async Task<Result<IReadOnlyList<NotificationDto>>> GetUserNotificationsAsync(CancellationToken cancellationToken = default)
    {
        if (!_currentUser.UserId.HasValue)
            return Result.Failure<IReadOnlyList<NotificationDto>>("Auth.Unauthorized", "User is not authenticated.");

        var notifications = await _notificationRepository.GetUserNotificationsAsync(_currentUser.UserId.Value, cancellationToken);
        var dtos = notifications.Select(n => new NotificationDto(
            n.Id,
            n.Title,
            n.Message,
            n.Type,
            n.IsRead,
            n.CreatedAt
        )).ToList();

        return Result.Success<IReadOnlyList<NotificationDto>>(dtos);
    }

    public async Task<Result<bool>> MarkAsReadAsync(Guid notificationId, CancellationToken cancellationToken = default)
    {
        if (!_currentUser.UserId.HasValue)
            return Result.Failure<bool>("Auth.Unauthorized", "User is not authenticated.");

        var notification = await _notificationRepository.GetByIdAsync(notificationId, cancellationToken);
        if (notification is null)
            return Result.Failure<bool>("Notification.NotFound", "Notification not found.");

        if (notification.UserId != _currentUser.UserId.Value)
            return Result.Failure<bool>("Notification.Forbidden", "Access denied.");

        notification.MarkAsRead();
        await _notificationRepository.UpdateAsync(notification, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return Result.Success(true);
    }

    public async Task<Result<bool>> SendNotificationAsync(Guid userId, string title, string message, NotificationType type, CancellationToken cancellationToken = default)
    {
        var notification = new InAppNotification(userId, title, message, type);
        await _notificationRepository.AddAsync(notification, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return Result.Success(true);
    }
}

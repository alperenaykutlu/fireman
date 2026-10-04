using Fireman.Shared.Enums;

namespace Fireman.Contracts.Notifications;

public record NotificationDto(
    Guid Id,
    string Title,
    string Message,
    NotificationType Type,
    bool IsRead,
    DateTime CreatedAt
);

public record SendNotificationRequest(
    Guid UserId,
    string Title,
    string Message,
    NotificationType Type
);

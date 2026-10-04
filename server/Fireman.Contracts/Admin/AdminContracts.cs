using Fireman.Shared.Enums;

namespace Fireman.Contracts.Admin;

public record AdminBanUserRequest(Guid UserId, string Reason);

public record AdminGrantCurrencyRequest(
    Guid UserId,
    CurrencyType Type,
    int Amount,
    string Reason
);

public record AuditLogDto(
    Guid Id,
    Guid ActorUserId,
    string Action,
    string TargetEntity,
    string? TargetId,
    string Details,
    string? CorrelationId,
    DateTime CreatedAt
);

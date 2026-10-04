using Fireman.Domain.Common;
using Fireman.Shared.Enums;

namespace Fireman.Application.Events;

public record AntiCheatViolationDetectedEvent(
    Guid UserId,
    string Action,
    string Reason,
    AntiCheatSeverity Severity,
    DateTime OccurredAt
) : IDomainEvent;

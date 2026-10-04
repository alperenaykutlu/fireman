using Fireman.Domain.Common;

namespace Fireman.Domain.Audit;

public class AuditLog : Entity<Guid>
{
    public Guid ActorUserId { get; private set; }
    public string Action { get; private set; }
    public string TargetEntity { get; private set; }
    public string? TargetId { get; private set; }
    public string Details { get; private set; }
    public string? CorrelationId { get; private set; }

    public AuditLog(
        Guid actorUserId,
        string action,
        string targetEntity,
        string? targetId,
        string details,
        string? correlationId)
    {
        Id = Guid.NewGuid();
        ActorUserId = actorUserId;
        Action = action;
        TargetEntity = targetEntity;
        TargetId = targetId;
        Details = details;
        CorrelationId = correlationId;
        CreatedAt = DateTime.UtcNow;
    }
}

public interface IAuditLogRepository
{
    Task AddAsync(AuditLog log, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<AuditLog>> GetRecentLogsAsync(int count = 100, CancellationToken cancellationToken = default);
}

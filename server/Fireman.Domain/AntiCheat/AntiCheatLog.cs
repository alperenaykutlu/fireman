using Fireman.Domain.Common;
using Fireman.Shared.Enums;

namespace Fireman.Domain.AntiCheat;

public class AntiCheatLog : Entity<Guid>
{
    public Guid UserId { get; private set; }
    public string Action { get; private set; }
    public string Reason { get; private set; }
    public AntiCheatSeverity Severity { get; private set; }
    public DateTime ClientTimestamp { get; private set; }
    public DateTime ServerTimestamp { get; private set; }
    public string? MetadataJson { get; private set; }

    public AntiCheatLog(
        Guid userId,
        string action,
        string reason,
        AntiCheatSeverity severity,
        DateTime clientTimestamp,
        string? metadataJson = null)
    {
        Id = Guid.NewGuid();
        UserId = userId;
        Action = action;
        Reason = reason;
        Severity = severity;
        ClientTimestamp = clientTimestamp;
        ServerTimestamp = DateTime.UtcNow;
        MetadataJson = metadataJson;
        CreatedAt = DateTime.UtcNow;
    }
}

public interface IAntiCheatRepository
{
    Task LogViolationAsync(AntiCheatLog log, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<AntiCheatLog>> GetUserViolationsAsync(Guid userId, CancellationToken cancellationToken = default);
}

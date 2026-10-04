using Fireman.Domain.Audit;
using Fireman.Infrastructure.Persistence;

namespace Fireman.Infrastructure.Persistence.Repositories;

public class AuditLogRepository : IAuditLogRepository
{
    private readonly List<AuditLog> _logs = new();

    public Task AddAsync(AuditLog log, CancellationToken cancellationToken = default)
    {
        lock (_logs)
        {
            _logs.Add(log);
        }
        return Task.CompletedTask;
    }

    public Task<IReadOnlyList<AuditLog>> GetRecentLogsAsync(int count = 100, CancellationToken cancellationToken = default)
    {
        lock (_logs)
        {
            var result = _logs.OrderByDescending(l => l.CreatedAt).Take(count).ToList();
            return Task.FromResult<IReadOnlyList<AuditLog>>(result);
        }
    }
}

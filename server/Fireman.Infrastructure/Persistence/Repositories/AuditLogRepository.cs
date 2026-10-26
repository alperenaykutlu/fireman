using Fireman.Application.Common.Interfaces;
using Fireman.Domain.Audit;

namespace Fireman.Infrastructure.Persistence.Repositories;

public sealed class AuditLogRepository(IDocumentDatabase database) : IAuditLogRepository
{
    private const string Collection = "auditLogs";
    public Task AddAsync(AuditLog log, CancellationToken cancellationToken = default) => database.SetAsync(Collection, log.Id.ToString(), log, cancellationToken);
    public async Task<IReadOnlyList<AuditLog>> GetRecentLogsAsync(int count = 100, CancellationToken cancellationToken = default) =>
        (await database.GetAllAsync<AuditLog>(Collection, cancellationToken)).OrderByDescending(log => log.CreatedAt).Take(count).ToList();
}

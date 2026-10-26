using Fireman.Application.Common.Interfaces;

namespace Fireman.Infrastructure.Persistence;

public class UnitOfWork : IUnitOfWork
{
    private readonly IDocumentDatabase _database;

    public UnitOfWork(IDocumentDatabase database)
    {
        _database = database;
    }

    public Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        // Writes are committed by each selected document provider at repository boundaries.
        _ = _database;
        return Task.FromResult(1);
    }
}

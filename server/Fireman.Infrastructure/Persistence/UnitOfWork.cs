using Fireman.Application.Common.Interfaces;

namespace Fireman.Infrastructure.Persistence;

public class UnitOfWork : IUnitOfWork
{
    private readonly InMemoryDbContext _context;

    public UnitOfWork(InMemoryDbContext context)
    {
        _context = context;
    }

    public Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        // For in-memory context, mutation is concurrent; return affected count
        return Task.FromResult(1);
    }
}

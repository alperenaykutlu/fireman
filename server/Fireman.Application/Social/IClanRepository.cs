using Fireman.Domain.Social;

namespace Fireman.Application.Social;

public interface IClanRepository
{
    Task<Clan?> GetByIdAsync(Guid clanId, CancellationToken cancellationToken = default);
    Task<Clan?> GetByUserIdAsync(Guid userId, CancellationToken cancellationToken = default);
    Task<bool> NameOrTagExistsAsync(string name, string tag, CancellationToken cancellationToken = default);
    Task AddAsync(Clan clan, CancellationToken cancellationToken = default);
    Task UpdateAsync(Clan clan, CancellationToken cancellationToken = default);
    Task<List<Clan>> SearchClansAsync(string query, int limit = 20, CancellationToken cancellationToken = default);
}

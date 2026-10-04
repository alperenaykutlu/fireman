using Fireman.Domain.Social;

namespace Fireman.Infrastructure.Persistence.Repositories;

public class FriendshipRepository : IFriendshipRepository
{
    private readonly List<Friendship> _friendships = new();

    public Task<IReadOnlyList<Friendship>> GetUserFriendshipsAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        lock (_friendships)
        {
            var list = _friendships.Where(f => f.UserId == userId || f.FriendUserId == userId).ToList();
            return Task.FromResult<IReadOnlyList<Friendship>>(list);
        }
    }

    public Task<Friendship?> GetBetweenUsersAsync(Guid userA, Guid userB, CancellationToken cancellationToken = default)
    {
        lock (_friendships)
        {
            var found = _friendships.FirstOrDefault(f =>
                (f.UserId == userA && f.FriendUserId == userB) ||
                (f.UserId == userB && f.FriendUserId == userA));
            return Task.FromResult(found);
        }
    }

    public Task AddAsync(Friendship friendship, CancellationToken cancellationToken = default)
    {
        lock (_friendships)
        {
            _friendships.Add(friendship);
        }
        return Task.CompletedTask;
    }

    public Task UpdateAsync(Friendship friendship, CancellationToken cancellationToken = default)
    {
        // Reference is updated in memory
        return Task.CompletedTask;
    }
}

public class PlayerReportRepository : IPlayerReportRepository
{
    private readonly List<PlayerReport> _reports = new();

    public Task AddAsync(PlayerReport report, CancellationToken cancellationToken = default)
    {
        lock (_reports)
        {
            _reports.Add(report);
        }
        return Task.CompletedTask;
    }

    public Task<IReadOnlyList<PlayerReport>> GetReportsForUserAsync(Guid reportedUserId, CancellationToken cancellationToken = default)
    {
        lock (_reports)
        {
            var list = _reports.Where(r => r.ReportedUserId == reportedUserId).ToList();
            return Task.FromResult<IReadOnlyList<PlayerReport>>(list);
        }
    }
}

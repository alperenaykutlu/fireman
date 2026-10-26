using Fireman.Application.Common.Interfaces;
using Fireman.Domain.Social;

namespace Fireman.Infrastructure.Persistence.Repositories;

public sealed class FriendshipRepository(IDocumentDatabase database) : IFriendshipRepository
{
    private const string Collection = "friendships";
    public async Task<IReadOnlyList<Friendship>> GetUserFriendshipsAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        var userFilter = new Dictionary<string, string> { ["userId"] = userId.ToString() };
        var friendFilter = new Dictionary<string, string> { ["friendUserId"] = userId.ToString() };
        var own = await database.FindAsync<Friendship>(Collection, userFilter, cancellationToken);
        var received = await database.FindAsync<Friendship>(Collection, friendFilter, cancellationToken);
        return own.Concat(received).DistinctBy(friendship => friendship.Id).ToList();
    }
    public async Task<Friendship?> GetBetweenUsersAsync(Guid userA, Guid userB, CancellationToken cancellationToken = default) =>
        await FindBetweenAsync(userA, userB, cancellationToken);
    private async Task<Friendship?> FindBetweenAsync(Guid userA, Guid userB, CancellationToken cancellationToken)
    {
        var outgoing = await database.FindAsync<Friendship>(Collection, new Dictionary<string, string> { ["userId"] = userA.ToString(), ["friendUserId"] = userB.ToString() }, cancellationToken);
        if (outgoing.Count > 0) return outgoing[0];
        var incoming = await database.FindAsync<Friendship>(Collection, new Dictionary<string, string> { ["userId"] = userB.ToString(), ["friendUserId"] = userA.ToString() }, cancellationToken);
        return incoming.FirstOrDefault();
    }
    public Task AddAsync(Friendship friendship, CancellationToken cancellationToken = default) => database.SetAsync(Collection, friendship.Id.ToString(), friendship, cancellationToken);
    public Task UpdateAsync(Friendship friendship, CancellationToken cancellationToken = default) => database.SetAsync(Collection, friendship.Id.ToString(), friendship, cancellationToken);
}

public sealed class DirectMessageRepository(IDocumentDatabase database) : IDirectMessageRepository
{
    private const string Collection = "directMessages";
    public async Task<IReadOnlyList<DirectMessage>> GetConversationAsync(Guid userA, Guid userB, CancellationToken cancellationToken = default)
    {
        var sent = await database.FindAsync<DirectMessage>(Collection, new Dictionary<string, string> { ["senderUserId"] = userA.ToString(), ["recipientUserId"] = userB.ToString() }, cancellationToken);
        var received = await database.FindAsync<DirectMessage>(Collection, new Dictionary<string, string> { ["senderUserId"] = userB.ToString(), ["recipientUserId"] = userA.ToString() }, cancellationToken);
        return sent.Concat(received).OrderBy(m => m.CreatedAt).TakeLast(100).ToList();
    }
    public Task AddAsync(DirectMessage message, CancellationToken cancellationToken = default) => database.SetAsync(Collection, message.Id.ToString(), message, cancellationToken);
}

public sealed class PlayerReportRepository(IDocumentDatabase database) : IPlayerReportRepository
{
    private const string Collection = "playerReports";
    public Task AddAsync(PlayerReport report, CancellationToken cancellationToken = default) => database.SetAsync(Collection, report.Id.ToString(), report, cancellationToken);
    public async Task<IReadOnlyList<PlayerReport>> GetReportsForUserAsync(Guid reportedUserId, CancellationToken cancellationToken = default) =>
        await database.FindAsync<PlayerReport>(Collection, new Dictionary<string, string> { ["reportedUserId"] = reportedUserId.ToString() }, cancellationToken);
}

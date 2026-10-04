using Fireman.Domain.Common;
using Fireman.Shared.Enums;
using Fireman.Shared.Exceptions;

namespace Fireman.Domain.Social;

public class Friendship : Entity<Guid>
{
    public Guid UserId { get; private set; }
    public Guid FriendUserId { get; private set; }
    public FriendshipStatus Status { get; private set; }

    private Friendship() { }

    public static Friendship CreateRequest(Guid userId, Guid friendUserId)
    {
        if (userId == friendUserId)
            throw new ValidationException("Cannot send friend request to yourself.");

        return new Friendship
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            FriendUserId = friendUserId,
            Status = FriendshipStatus.Pending,
            CreatedAt = DateTime.UtcNow
        };
    }

    public void Accept()
    {
        if (Status != FriendshipStatus.Pending)
            throw new DomainException("Only pending friend requests can be accepted.");

        Status = FriendshipStatus.Accepted;
        UpdatedAt = DateTime.UtcNow;
    }

    public void Decline()
    {
        Status = FriendshipStatus.Declined;
        UpdatedAt = DateTime.UtcNow;
    }

    public void Block()
    {
        Status = FriendshipStatus.Blocked;
        UpdatedAt = DateTime.UtcNow;
    }
}

public class PlayerReport : Entity<Guid>
{
    public Guid ReporterUserId { get; private set; }
    public Guid ReportedUserId { get; private set; }
    public ReportReason Reason { get; private set; }
    public string Description { get; private set; }

    public PlayerReport(Guid reporterUserId, Guid reportedUserId, ReportReason reason, string description)
    {
        Id = Guid.NewGuid();
        ReporterUserId = reporterUserId;
        ReportedUserId = reportedUserId;
        Reason = reason;
        Description = description;
        CreatedAt = DateTime.UtcNow;
    }
}

public interface IFriendshipRepository
{
    Task<IReadOnlyList<Friendship>> GetUserFriendshipsAsync(Guid userId, CancellationToken cancellationToken = default);
    Task<Friendship?> GetBetweenUsersAsync(Guid userA, Guid userB, CancellationToken cancellationToken = default);
    Task AddAsync(Friendship friendship, CancellationToken cancellationToken = default);
    Task UpdateAsync(Friendship friendship, CancellationToken cancellationToken = default);
}

public interface IPlayerReportRepository
{
    Task AddAsync(PlayerReport report, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<PlayerReport>> GetReportsForUserAsync(Guid reportedUserId, CancellationToken cancellationToken = default);
}

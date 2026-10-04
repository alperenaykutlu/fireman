using Fireman.Application.Common.Interfaces;
using Fireman.Contracts.Social;
using Fireman.Domain.Social;
using Fireman.Domain.Users;
using Fireman.Shared.Enums;
using Fireman.Shared.Results;

namespace Fireman.Application.Social;

public interface ISocialService
{
    Task<Result<bool>> SendFriendRequestAsync(SendFriendRequest request, CancellationToken cancellationToken = default);
    Task<Result<bool>> RespondFriendRequestAsync(RespondFriendRequest request, CancellationToken cancellationToken = default);
    Task<Result<IReadOnlyList<FriendDto>>> GetFriendsAsync(CancellationToken cancellationToken = default);
    Task<Result<bool>> SubmitReportAsync(SubmitReportRequest request, CancellationToken cancellationToken = default);
}

public class SocialService : ISocialService
{
    private readonly IFriendshipRepository _friendshipRepository;
    private readonly IPlayerReportRepository _reportRepository;
    private readonly IUserRepository _userRepository;
    private readonly ICurrentUser _currentUser;
    private readonly IUnitOfWork _unitOfWork;

    public SocialService(
        IFriendshipRepository friendshipRepository,
        IPlayerReportRepository reportRepository,
        IUserRepository userRepository,
        ICurrentUser currentUser,
        IUnitOfWork unitOfWork)
    {
        _friendshipRepository = friendshipRepository;
        _reportRepository = reportRepository;
        _userRepository = userRepository;
        _currentUser = currentUser;
        _unitOfWork = unitOfWork;
    }

    public async Task<Result<bool>> SendFriendRequestAsync(SendFriendRequest request, CancellationToken cancellationToken = default)
    {
        if (!_currentUser.UserId.HasValue)
            return Result.Failure<bool>("Auth.Unauthorized", "User is not authenticated.");

        var userId = _currentUser.UserId.Value;
        if (userId == request.TargetUserId)
            return Result.Failure<bool>("Social.SelfRequest", "Cannot send friend request to yourself.");

        var targetUser = await _userRepository.GetByIdAsync(request.TargetUserId, cancellationToken);
        if (targetUser is null)
            return Result.Failure<bool>("User.NotFound", "Target user does not exist.");

        var existing = await _friendshipRepository.GetBetweenUsersAsync(userId, request.TargetUserId, cancellationToken);
        if (existing is not null)
        {
            if (existing.Status == FriendshipStatus.Accepted)
                return Result.Failure<bool>("Social.AlreadyFriends", "Already friends with this user.");
            if (existing.Status == FriendshipStatus.Pending)
                return Result.Failure<bool>("Social.RequestPending", "Friend request is already pending.");
            if (existing.Status == FriendshipStatus.Blocked)
                return Result.Failure<bool>("Social.Blocked", "Cannot send request to this user.");
        }

        var friendship = Friendship.CreateRequest(userId, request.TargetUserId);
        await _friendshipRepository.AddAsync(friendship, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return Result.Success(true);
    }

    public async Task<Result<bool>> RespondFriendRequestAsync(RespondFriendRequest request, CancellationToken cancellationToken = default)
    {
        if (!_currentUser.UserId.HasValue)
            return Result.Failure<bool>("Auth.Unauthorized", "User is not authenticated.");

        var friendships = await _friendshipRepository.GetUserFriendshipsAsync(_currentUser.UserId.Value, cancellationToken);
        var friendship = friendships.FirstOrDefault(f => f.Id == request.FriendshipId);

        if (friendship is null)
            return Result.Failure<bool>("Social.NotFound", "Friend request not found.");

        if (friendship.FriendUserId != _currentUser.UserId.Value)
            return Result.Failure<bool>("Social.Forbidden", "Only the recipient can respond to this friend request.");

        if (request.Accept)
        {
            friendship.Accept();
        }
        else
        {
            friendship.Decline();
        }

        await _friendshipRepository.UpdateAsync(friendship, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return Result.Success(true);
    }

    public async Task<Result<IReadOnlyList<FriendDto>>> GetFriendsAsync(CancellationToken cancellationToken = default)
    {
        if (!_currentUser.UserId.HasValue)
            return Result.Failure<IReadOnlyList<FriendDto>>("Auth.Unauthorized", "User is not authenticated.");

        var userId = _currentUser.UserId.Value;
        var list = await _friendshipRepository.GetUserFriendshipsAsync(userId, cancellationToken);

        var dtos = new List<FriendDto>();
        foreach (var f in list)
        {
            var otherId = f.UserId == userId ? f.FriendUserId : f.UserId;
            var user = await _userRepository.GetByIdAsync(otherId, cancellationToken);

            dtos.Add(new FriendDto(
                f.Id,
                otherId,
                user?.Username.Value ?? "Unknown",
                f.Status,
                f.CreatedAt));
        }

        return Result.Success<IReadOnlyList<FriendDto>>(dtos);
    }

    public async Task<Result<bool>> SubmitReportAsync(SubmitReportRequest request, CancellationToken cancellationToken = default)
    {
        if (!_currentUser.UserId.HasValue)
            return Result.Failure<bool>("Auth.Unauthorized", "User is not authenticated.");

        var report = new PlayerReport(
            _currentUser.UserId.Value,
            request.ReportedUserId,
            request.Reason,
            request.Description);

        await _reportRepository.AddAsync(report, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return Result.Success(true);
    }
}

using Fireman.Application.AntiCheat;
using Fireman.Application.Common.Interfaces;
using Fireman.Application.Policies;
using Fireman.Contracts.Matches;
using Fireman.Domain.Matches;
using Fireman.Domain.Users;
using Fireman.Domain.Social;
using Fireman.Domain.Notifications;
using Fireman.Shared.Enums;
using Fireman.Shared.Results;
using MatchType = Fireman.Shared.Enums.MatchType;
using System.Security.Cryptography;
using System.Text;

namespace Fireman.Application.Matches;

public interface IMatchService
{
    Task<Result<MatchDto>> CreateMatchAsync(CreateMatchRequest request, CancellationToken cancellationToken = default);
    Task<Result<MatchDto>> JoinMatchAsync(JoinMatchRequest request, CancellationToken cancellationToken = default);
    Task<Result<MatchDto>> GetMatchAsync(Guid matchId, CancellationToken cancellationToken = default);
    Task<Result<MatchDto>> SubmitScoreAsync(SubmitMatchScoreRequest request, CancellationToken cancellationToken = default);
    Task<Result<IReadOnlyList<MatchDto>>> GetOpenMatchesAsync(CancellationToken cancellationToken = default);
    Task<Result<MatchDto>> QuickMatchAsync(MatchType type, int maxPlayers, CancellationToken cancellationToken = default);
    Task<Result<int>> InviteFriendsAsync(Guid matchId, CancellationToken cancellationToken = default);
    Task<Result<bool>> LeaveMatchAsync(Guid matchId, CancellationToken cancellationToken = default);
}
public class MatchService : IMatchService
{
    private readonly IMatchRepository _matchRepository;
    private readonly IUserRepository _userRepository;
    private readonly ICurrentUser _currentUser;
    private readonly IUnitOfWork _unitOfWork;
    private readonly CanJoinMatchPolicy _canJoinMatchPolicy;
    private readonly IAntiCheatValidationService _antiCheatService;
    private readonly IFriendshipRepository _friendshipRepository;
    private readonly INotificationRepository _notificationRepository;

    public MatchService(
        IMatchRepository matchRepository,
        IUserRepository userRepository,
        ICurrentUser currentUser,
        IUnitOfWork unitOfWork,
        CanJoinMatchPolicy canJoinMatchPolicy,
        IAntiCheatValidationService antiCheatService,
        IFriendshipRepository friendshipRepository,
        INotificationRepository notificationRepository)
    {
        _matchRepository = matchRepository;
        _userRepository = userRepository;
        _currentUser = currentUser;
        _unitOfWork = unitOfWork;
        _canJoinMatchPolicy = canJoinMatchPolicy;
        _antiCheatService = antiCheatService;
        _friendshipRepository = friendshipRepository;
        _notificationRepository = notificationRepository;
    }

    public async Task<Result<int>> InviteFriendsAsync(Guid matchId, CancellationToken cancellationToken = default)
    {
        if (!_currentUser.UserId.HasValue)
            return Result.Failure<int>("Auth.Unauthorized", "User is not authenticated.");

        var match = await _matchRepository.GetByIdAsync(matchId, cancellationToken);
        if (match is null)
            return Result.Failure<int>("Match.NotFound", "Match not found.");
        if (match.HostUserId != _currentUser.UserId.Value)
            return Result.Failure<int>("Match.InviteDenied", "Only the room host can invite friends.");

        var friendships = await _friendshipRepository.GetUserFriendshipsAsync(_currentUser.UserId.Value, cancellationToken);
        var invitedIds = friendships
            .Where(friendship => friendship.Status == FriendshipStatus.Accepted)
            .Select(friendship => friendship.UserId == _currentUser.UserId.Value ? friendship.FriendUserId : friendship.UserId)
            .Distinct()
            .ToArray();
        var hostName = match.Players.FirstOrDefault(player => player.UserId == match.HostUserId)?.Username ?? "Arkadaşın";

        foreach (var friendId in invitedIds)
        {
            var invitation = new InAppNotification(
                friendId,
                "Oyun daveti",
                $"{hostName} seni “{match.RoomName}” odasına çağırıyor. Oda kodu: {match.Id}",
                NotificationType.MatchInvite);
            await _notificationRepository.AddAsync(invitation, cancellationToken);
        }

        if (invitedIds.Length > 0)
            await _unitOfWork.SaveChangesAsync(cancellationToken);

        return Result.Success(invitedIds.Length);
    }

    public async Task<Result<MatchDto>> CreateMatchAsync(CreateMatchRequest request, CancellationToken cancellationToken = default)
    {
        if (!_currentUser.UserId.HasValue)
            return Result.Failure<MatchDto>("Auth.Unauthorized", "User is not authenticated.");

        var user = await _userRepository.GetByIdAsync(_currentUser.UserId.Value, cancellationToken);
        if (user is null)
            return Result.Failure<MatchDto>("User.NotFound", "User not found.");

        if (string.IsNullOrWhiteSpace(request.RoomName) || request.RoomName.Trim().Length > 40)
            return Result.Failure<MatchDto>("Match.InvalidRoomName", "Room name must be between 1 and 40 characters.");
        if (!string.IsNullOrEmpty(request.Password) && request.Password.Length < 4)
            return Result.Failure<MatchDto>("Match.InvalidPassword", "Room password must be at least 4 characters.");

        var passwordHash = string.IsNullOrEmpty(request.Password) ? null : HashPassword(request.Password);
        var match = Match.Create(user.Id, user.Username.Value, request.Type, request.MaxPlayers, request.RoomName, passwordHash);
        await _matchRepository.AddAsync(match, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return Result.Success(MapToDto(match));
    }

    public async Task<Result<MatchDto>> JoinMatchAsync(JoinMatchRequest request, CancellationToken cancellationToken = default)
    {
        if (!_currentUser.UserId.HasValue)
            return Result.Failure<MatchDto>("Auth.Unauthorized", "User is not authenticated.");

        var user = await _userRepository.GetByIdAsync(_currentUser.UserId.Value, cancellationToken);
        var match = await _matchRepository.GetByIdAsync(request.MatchId, cancellationToken);

        if (user is null || match is null)
            return Result.Failure<MatchDto>("Match.NotFound", "Match or user not found.");

        if (!match.ValidatePassword(string.IsNullOrEmpty(request.Password) ? null : HashPassword(request.Password)))
            return Result.Failure<MatchDto>("Match.InvalidPassword", "Room password is incorrect.");

        var policyResult = _canJoinMatchPolicy.Evaluate(new CanJoinMatchContext(user, match, match.Players.Count));
        if (!policyResult.IsAllowed)
            return Result.Failure<MatchDto>("Match.JoinDenied", policyResult.Reason ?? "Join policy denied.");

        match.Join(user.Id, user.Username.Value);
        await _matchRepository.UpdateAsync(match, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return Result.Success(MapToDto(match));
    }

    public async Task<Result<IReadOnlyList<MatchDto>>> GetOpenMatchesAsync(CancellationToken cancellationToken = default)
    {
        var matches = await _matchRepository.GetActiveMatchesAsync(cancellationToken);
        var open = matches.Where(m => m.Status == MatchStatus.Lobby && m.Players.Count < m.MaxPlayers)
            .Select(MapToDto).ToList();
        return Result.Success<IReadOnlyList<MatchDto>>(open);
    }

    public async Task<Result<MatchDto>> QuickMatchAsync(MatchType type, int maxPlayers, CancellationToken cancellationToken = default)
    {
        var matches = await _matchRepository.GetActiveMatchesAsync(cancellationToken);
        var available = matches.FirstOrDefault(m => m.Type == type && m.Status == MatchStatus.Lobby &&
            !m.HasPassword && m.Players.Count < m.MaxPlayers &&
            (! _currentUser.UserId.HasValue || m.Players.All(p => p.UserId != _currentUser.UserId.Value)));
        if (available is not null)
            return await JoinMatchAsync(new JoinMatchRequest(available.Id), cancellationToken);

        return await CreateMatchAsync(new CreateMatchRequest(type, maxPlayers, "Rastgele Oda"), cancellationToken);
    }

    public async Task<Result<bool>> LeaveMatchAsync(Guid matchId, CancellationToken cancellationToken = default)
    {
        if (!_currentUser.UserId.HasValue)
            return Result.Failure<bool>("Auth.Unauthorized", "User is not authenticated.");
        var match = await _matchRepository.GetByIdAsync(matchId, cancellationToken);
        if (match is null)
            return Result.Success(true);
        if (!match.Players.Any(p => p.UserId == _currentUser.UserId.Value))
            return Result.Success(true);
        match.Leave(_currentUser.UserId.Value);
        if (match.Players.Count == 0)
            await _matchRepository.RemoveAsync(matchId, cancellationToken);
        else
            await _matchRepository.UpdateAsync(match, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);
        return Result.Success(true);
    }

    private static string HashPassword(string password) => Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(password)));

    public async Task<Result<MatchDto>> GetMatchAsync(Guid matchId, CancellationToken cancellationToken = default)
    {
        var match = await _matchRepository.GetByIdAsync(matchId, cancellationToken);
        if (match is null)
            return Result.Failure<MatchDto>("Match.NotFound", "Match not found.");

        return Result.Success(MapToDto(match));
    }

    public async Task<Result<MatchDto>> SubmitScoreAsync(SubmitMatchScoreRequest request, CancellationToken cancellationToken = default)
    {
        if (!_currentUser.UserId.HasValue)
            return Result.Failure<MatchDto>("Auth.Unauthorized", "User is not authenticated.");

        var match = await _matchRepository.GetByIdAsync(request.MatchId, cancellationToken);
        if (match is null)
            return Result.Failure<MatchDto>("Match.NotFound", "Match not found.");

        var validation = await _antiCheatService.ValidateScoreSubmissionAsync(
            _currentUser.UserId.Value,
            request.Score,
            request.Rescues,
            elapsedSeconds: 60.0,
            cancellationToken);

        if (!validation.IsValid)
            return Result.Failure<MatchDto>("AntiCheat.ScoreRejected", validation.ViolationReason ?? "Score rejected by anti-cheat.");

        match.RecordPlayerScore(_currentUser.UserId.Value, request.Score, request.Rescues);
        await _matchRepository.UpdateAsync(match, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return Result.Success(MapToDto(match));
    }

    private static MatchDto MapToDto(Match match)
    {
        var playerDtos = match.Players.Select(p => new MatchPlayerDto(
            p.UserId,
            p.Username,
            p.Score,
            p.Rescues,
            p.IsReady
        )).ToList();

        return new MatchDto(
            match.Id,
            match.Type,
            match.Status,
            match.HostUserId,
            match.MaxPlayers,
            playerDtos,
            match.CreatedAt,
            match.StartedAt,
            match.FinishedAt,
            match.RoomName,
            match.HasPassword);
    }
}

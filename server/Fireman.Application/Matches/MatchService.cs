using Fireman.Application.Common.Interfaces;
using Fireman.Contracts.Matches;
using Fireman.Domain.Matches;
using Fireman.Domain.Users;
using Fireman.Shared.Enums;
using Fireman.Shared.Results;
using MatchType = Fireman.Shared.Enums.MatchType;

namespace Fireman.Application.Matches;

public interface IMatchService
{
    Task<Result<MatchDto>> CreateMatchAsync(CreateMatchRequest request, CancellationToken cancellationToken = default);
    Task<Result<MatchDto>> JoinMatchAsync(JoinMatchRequest request, CancellationToken cancellationToken = default);
    Task<Result<MatchDto>> GetMatchAsync(Guid matchId, CancellationToken cancellationToken = default);
    Task<Result<MatchDto>> SubmitScoreAsync(SubmitMatchScoreRequest request, CancellationToken cancellationToken = default);
}

public class MatchService : IMatchService
{
    private readonly IMatchRepository _matchRepository;
    private readonly IUserRepository _userRepository;
    private readonly ICurrentUser _currentUser;
    private readonly IUnitOfWork _unitOfWork;

    public MatchService(
        IMatchRepository matchRepository,
        IUserRepository userRepository,
        ICurrentUser currentUser,
        IUnitOfWork unitOfWork)
    {
        _matchRepository = matchRepository;
        _userRepository = userRepository;
        _currentUser = currentUser;
        _unitOfWork = unitOfWork;
    }

    public async Task<Result<MatchDto>> CreateMatchAsync(CreateMatchRequest request, CancellationToken cancellationToken = default)
    {
        if (!_currentUser.UserId.HasValue)
            return Result.Failure<MatchDto>("Auth.Unauthorized", "User is not authenticated.");

        var user = await _userRepository.GetByIdAsync(_currentUser.UserId.Value, cancellationToken);
        if (user is null)
            return Result.Failure<MatchDto>("User.NotFound", "User not found.");

        var match = Match.Create(user.Id, user.Username.Value, request.Type, request.MaxPlayers);
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

        match.Join(user.Id, user.Username.Value);
        await _matchRepository.UpdateAsync(match, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return Result.Success(MapToDto(match));
    }

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
            match.FinishedAt);
    }
}

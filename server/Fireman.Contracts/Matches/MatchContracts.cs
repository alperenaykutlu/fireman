using Fireman.Shared.Enums;
using MatchType = Fireman.Shared.Enums.MatchType;

namespace Fireman.Contracts.Matches;

public record MatchPlayerDto(
    Guid UserId,
    string Username,
    int Score,
    int Rescues,
    bool IsReady
);

public record MatchDto(
    Guid Id,
    MatchType Type,
    MatchStatus Status,
    Guid HostUserId,
    int MaxPlayers,
    List<MatchPlayerDto> Players,
    DateTime CreatedAt,
    DateTime? StartedAt,
    DateTime? FinishedAt
);

public record CreateMatchRequest(MatchType Type, int MaxPlayers);

public record JoinMatchRequest(Guid MatchId);

public record SubmitMatchScoreRequest(Guid MatchId, int Score, int Rescues);

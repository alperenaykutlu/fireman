using Fireman.Domain.Matches;
using Fireman.Domain.Policies;
using Fireman.Domain.Users;
using Fireman.Shared.Enums;

namespace Fireman.Application.Policies;

public record CanJoinMatchContext(
    User User,
    Match Match,
    int CurrentPlayerCount
);

public class CanJoinMatchPolicy : IGamePolicy<CanJoinMatchContext>
{
    public PolicyResult Evaluate(CanJoinMatchContext context)
    {
        if (context.User.Status != UserStatus.Active)
            return PolicyResult.Deny("User account is not active or is suspended.");

        if (context.Match.Status != MatchStatus.Lobby)
            return PolicyResult.Deny($"Match is not accepting players. Current status: {context.Match.Status}");

        if (context.CurrentPlayerCount >= context.Match.MaxPlayers)
            return PolicyResult.Deny("Match is already full.");

        return PolicyResult.Allow();
    }
}

using Fireman.Domain.Characters;
using Fireman.Domain.Missions;
using Fireman.Domain.Policies;
using Fireman.Domain.Users;
using Fireman.Shared.Enums;

namespace Fireman.Application.Policies;

public record CanStartMissionContext(
    User User,
    Character Character,
    Mission Mission,
    UserMission? ActiveMission
);

public class CanStartMissionPolicy : IGamePolicy<CanStartMissionContext>
{
    public PolicyResult Evaluate(CanStartMissionContext context)
    {
        if (context.User.Status != UserStatus.Active)
            return PolicyResult.Deny("User account is not active.");

        if (context.Character.Level < context.Mission.RequiredLevel)
            return PolicyResult.Deny($"Level {context.Mission.RequiredLevel} required to start this mission. Current level: {context.Character.Level}");

        if (context.ActiveMission is not null && context.ActiveMission.Status == MissionStatus.InProgress)
            return PolicyResult.Deny("Another mission is already in progress.");

        return PolicyResult.Allow();
    }
}

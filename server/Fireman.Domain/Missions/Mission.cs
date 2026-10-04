using Fireman.Domain.Common;
using Fireman.Shared.Enums;

namespace Fireman.Domain.Missions;

public class Mission : Entity<Guid>
{
    public string Title { get; private set; } = string.Empty;
    public string Description { get; private set; } = string.Empty;
    public MissionType Type { get; private set; }
    public int RequiredLevel { get; private set; }
    public int BaseRewardCoins { get; private set; }
    public int BaseRewardXp { get; private set; }
    public int TargetScore { get; private set; }

    private Mission() { }

    public Mission(
        Guid id,
        string title,
        string description,
        MissionType type,
        int requiredLevel,
        int baseRewardCoins,
        int baseRewardXp,
        int targetScore)
    {
        Id = id;
        Title = title;
        Description = description;
        Type = type;
        RequiredLevel = requiredLevel;
        BaseRewardCoins = baseRewardCoins;
        BaseRewardXp = baseRewardXp;
        TargetScore = targetScore;
        CreatedAt = DateTime.UtcNow;
    }
}

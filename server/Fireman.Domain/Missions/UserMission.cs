using Fireman.Domain.Common;
using Fireman.Shared.Enums;
using Fireman.Shared.Exceptions;

namespace Fireman.Domain.Missions;

public class UserMission : AggregateRoot<Guid>
{
    public Guid UserId { get; private set; }
    public Guid MissionId { get; private set; }
    public MissionStatus Status { get; private set; }
    public int CurrentScore { get; private set; }
    public int TargetScore { get; private set; }
    public DateTime? StartedAt { get; private set; }
    public DateTime? CompletedAt { get; private set; }

    private UserMission() { }

    public static UserMission Create(Guid userId, Guid missionId, int targetScore)
    {
        return new UserMission
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            MissionId = missionId,
            Status = MissionStatus.Available,
            CurrentScore = 0,
            TargetScore = targetScore,
            CreatedAt = DateTime.UtcNow
        };
    }

    public void Start()
    {
        if (Status == MissionStatus.InProgress)
            throw new DomainException("Mission is already in progress.");

        if (Status == MissionStatus.Completed || Status == MissionStatus.RewardClaimed)
            throw new DomainException("Mission is already completed.");

        Status = MissionStatus.InProgress;
        StartedAt = DateTime.UtcNow;
        UpdatedAt = DateTime.UtcNow;
    }

    public void RecordScore(int score)
    {
        if (Status != MissionStatus.InProgress)
            throw new DomainException("Cannot record score for mission that is not in progress.");

        CurrentScore += score;
        if (CurrentScore >= TargetScore)
        {
            Status = MissionStatus.Completed;
            CompletedAt = DateTime.UtcNow;
        }

        UpdatedAt = DateTime.UtcNow;
    }

    public void ClaimReward()
    {
        if (Status != MissionStatus.Completed)
            throw new DomainException("Cannot claim reward for non-completed mission.");

        Status = MissionStatus.RewardClaimed;
        UpdatedAt = DateTime.UtcNow;
    }
}

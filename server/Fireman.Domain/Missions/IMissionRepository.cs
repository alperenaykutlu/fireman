namespace Fireman.Domain.Missions;

public interface IMissionRepository
{
    Task<IReadOnlyList<Mission>> GetAllAsync(CancellationToken cancellationToken = default);
    Task<Mission?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task AddAsync(Mission mission, CancellationToken cancellationToken = default);
}

public interface IUserMissionRepository
{
    Task<IReadOnlyList<UserMission>> GetByUserIdAsync(Guid userId, CancellationToken cancellationToken = default);
    Task<UserMission?> GetByUserAndMissionIdAsync(Guid userId, Guid missionId, CancellationToken cancellationToken = default);
    Task<UserMission?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task AddAsync(UserMission userMission, CancellationToken cancellationToken = default);
    Task UpdateAsync(UserMission userMission, CancellationToken cancellationToken = default);
}

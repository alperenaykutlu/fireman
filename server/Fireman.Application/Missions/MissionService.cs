using Fireman.Application.Common.Interfaces;
using Fireman.Application.Events;
using Fireman.Application.Policies;
using Fireman.Application.Strategies.Rewards;
using Fireman.Contracts.Missions;
using Fireman.Domain.Characters;
using Fireman.Domain.Economy;
using Fireman.Domain.Missions;
using Fireman.Domain.Policies;
using Fireman.Domain.Users;
using Fireman.Shared.Enums;
using Fireman.Shared.Results;

namespace Fireman.Application.Missions;

public interface IMissionService
{
    Task<Result<IReadOnlyList<MissionDto>>> GetAvailableMissionsAsync(CancellationToken cancellationToken = default);
    Task<Result<UserMissionDto>> StartMissionAsync(StartMissionRequest request, CancellationToken cancellationToken = default);
    Task<Result<MissionCompletionResultDto>> CompleteMissionAsync(CompleteMissionRequest request, CancellationToken cancellationToken = default);
}

public class MissionService : IMissionService
{
    private readonly IMissionRepository _missionRepository;
    private readonly IUserMissionRepository _userMissionRepository;
    private readonly IUserRepository _userRepository;
    private readonly ICharacterRepository _characterRepository;
    private readonly IWalletRepository _walletRepository;
    private readonly ICurrencyLedgerRepository _ledgerRepository;
    private readonly IRewardStrategyFactory _rewardStrategyFactory;
    private readonly IGamePolicy<CanStartMissionContext> _canStartMissionPolicy;
    private readonly IEventBus _eventBus;
    private readonly ICurrentUser _currentUser;
    private readonly IUnitOfWork _unitOfWork;

    public MissionService(
        IMissionRepository missionRepository,
        IUserMissionRepository userMissionRepository,
        IUserRepository userRepository,
        ICharacterRepository characterRepository,
        IWalletRepository walletRepository,
        ICurrencyLedgerRepository ledgerRepository,
        IRewardStrategyFactory rewardStrategyFactory,
        IGamePolicy<CanStartMissionContext> canStartMissionPolicy,
        IEventBus eventBus,
        ICurrentUser currentUser,
        IUnitOfWork unitOfWork)
    {
        _missionRepository = missionRepository;
        _userMissionRepository = userMissionRepository;
        _userRepository = userRepository;
        _characterRepository = characterRepository;
        _walletRepository = walletRepository;
        _ledgerRepository = ledgerRepository;
        _rewardStrategyFactory = rewardStrategyFactory;
        _canStartMissionPolicy = canStartMissionPolicy;
        _eventBus = eventBus;
        _currentUser = currentUser;
        _unitOfWork = unitOfWork;
    }

    public async Task<Result<IReadOnlyList<MissionDto>>> GetAvailableMissionsAsync(CancellationToken cancellationToken = default)
    {
        var missions = await _missionRepository.GetAllAsync(cancellationToken);
        var dtos = missions.Select(m => new MissionDto(
            m.Id,
            m.Title,
            m.Description,
            m.Type,
            m.RequiredLevel,
            m.BaseRewardCoins,
            m.BaseRewardXp,
            m.TargetScore
        )).ToList();

        return Result.Success<IReadOnlyList<MissionDto>>(dtos);
    }

    public async Task<Result<UserMissionDto>> StartMissionAsync(StartMissionRequest request, CancellationToken cancellationToken = default)
    {
        if (!_currentUser.UserId.HasValue)
            return Result.Failure<UserMissionDto>("Auth.Unauthorized", "User is not authenticated.");

        var user = await _userRepository.GetByIdAsync(_currentUser.UserId.Value, cancellationToken);
        var character = await _characterRepository.GetByUserIdAsync(_currentUser.UserId.Value, cancellationToken);
        var mission = await _missionRepository.GetByIdAsync(request.MissionId, cancellationToken);

        if (user is null || character is null)
            return Result.Failure<UserMissionDto>("User.NotFound", "User or character not found.");

        if (mission is null)
            return Result.Failure<UserMissionDto>("Mission.NotFound", "Mission not found.");

        var activeMission = await _userMissionRepository.GetByUserAndMissionIdAsync(user.Id, mission.Id, cancellationToken);

        var policyResult = _canStartMissionPolicy.Evaluate(new CanStartMissionContext(user, character, mission, activeMission));
        if (!policyResult.IsAllowed)
            return Result.Failure<UserMissionDto>("Mission.CannotStart", policyResult.Reason ?? "Cannot start mission.");

        UserMission userMission;
        if (activeMission is null)
        {
            userMission = UserMission.Create(user.Id, mission.Id, mission.TargetScore);
            userMission.Start();
            await _userMissionRepository.AddAsync(userMission, cancellationToken);
        }
        else
        {
            userMission = activeMission;
            userMission.Start();
            await _userMissionRepository.UpdateAsync(userMission, cancellationToken);
        }

        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return Result.Success(new UserMissionDto(
            userMission.Id,
            mission.Id,
            mission.Title,
            mission.Type,
            userMission.Status,
            userMission.CurrentScore,
            userMission.TargetScore,
            userMission.StartedAt,
            userMission.CompletedAt));
    }

    public async Task<Result<MissionCompletionResultDto>> CompleteMissionAsync(CompleteMissionRequest request, CancellationToken cancellationToken = default)
    {
        if (!_currentUser.UserId.HasValue)
            return Result.Failure<MissionCompletionResultDto>("Auth.Unauthorized", "User is not authenticated.");

        var user = await _userRepository.GetByIdAsync(_currentUser.UserId.Value, cancellationToken);
        var character = await _characterRepository.GetByUserIdAsync(_currentUser.UserId.Value, cancellationToken);
        var mission = await _missionRepository.GetByIdAsync(request.MissionId, cancellationToken);
        var userMission = await _userMissionRepository.GetByUserAndMissionIdAsync(_currentUser.UserId.Value, request.MissionId, cancellationToken);

        if (user is null || character is null || userMission is null || mission is null)
            return Result.Failure<MissionCompletionResultDto>("Mission.NotFound", "Active mission not found.");

        // Record progress & complete
        userMission.RecordScore(request.FinalScore);
        if (userMission.Status != MissionStatus.Completed)
            return Result.Failure<MissionCompletionResultDto>("Mission.TargetNotMet", "Mission target score was not met.");

        userMission.ClaimReward();
        await _userMissionRepository.UpdateAsync(userMission, cancellationToken);

        // Calculate reward via strategy pattern (Role-dependent multiplier)
        var rewardStrategy = _rewardStrategyFactory.GetStrategy(user.Role);
        var rewardResult = rewardStrategy.Calculate(new RewardContext(
            user.Id,
            user.Role,
            mission.BaseRewardCoins,
            mission.BaseRewardXp,
            request.RescuesCompleted));

        // Credit wallet
        var wallet = await _walletRepository.GetByUserIdAsync(user.Id, cancellationToken);
        if (wallet is not null)
        {
            wallet.AddCurrency(CurrencyType.Coins, rewardResult.TotalCoins);
            await _walletRepository.UpdateAsync(wallet, cancellationToken);

            var ledgerEntry = new CurrencyLedgerEntry(
                user.Id,
                CurrencyType.Coins,
                rewardResult.TotalCoins,
                $"Mission completed: {mission.Title} ({rewardResult.StrategyApplied})",
                wallet.Coins);
            await _ledgerRepository.AddEntryAsync(ledgerEntry, cancellationToken);
        }

        // Add character XP & check level up
        bool leveledUp = character.AddExperience(rewardResult.TotalXp, out int newLevel);
        await _characterRepository.UpdateAsync(character, cancellationToken);

        await _unitOfWork.SaveChangesAsync(cancellationToken);

        // Publish event to decoupled event bus
        await _eventBus.PublishAsync(new MissionCompletedEvent(
            user.Id,
            mission.Id,
            request.FinalScore,
            request.RescuesCompleted,
            rewardResult.TotalCoins,
            rewardResult.TotalXp), cancellationToken);

        return Result.Success(new MissionCompletionResultDto(
            true,
            mission.Id,
            rewardResult.TotalCoins,
            rewardResult.TotalXp,
            leveledUp,
            newLevel,
            $"Completed using {rewardResult.StrategyApplied} strategy!"));
    }
}

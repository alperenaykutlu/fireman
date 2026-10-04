using Fireman.Application.Common.Interfaces;
using Fireman.Contracts.Seasons;
using Fireman.Domain.Economy;
using Fireman.Domain.Seasons;
using Fireman.Shared.Enums;
using Fireman.Shared.Results;

namespace Fireman.Application.Seasons;

public interface ISeasonService
{
    Task<Result<SeasonDto>> GetActiveSeasonAsync(CancellationToken cancellationToken = default);
    Task<Result<UserSeasonProgressDto>> GetUserProgressAsync(CancellationToken cancellationToken = default);
    Task<Result<bool>> ClaimTierRewardAsync(ClaimSeasonTierRequest request, CancellationToken cancellationToken = default);
}

public class SeasonService : ISeasonService
{
    private readonly ISeasonRepository _seasonRepository;
    private readonly IWalletRepository _walletRepository;
    private readonly ICurrencyLedgerRepository _currencyLedgerRepository;
    private readonly ICurrentUser _currentUser;
    private readonly IUnitOfWork _unitOfWork;

    public SeasonService(
        ISeasonRepository seasonRepository,
        IWalletRepository walletRepository,
        ICurrencyLedgerRepository currencyLedgerRepository,
        ICurrentUser currentUser,
        IUnitOfWork unitOfWork)
    {
        _seasonRepository = seasonRepository;
        _walletRepository = walletRepository;
        _currencyLedgerRepository = currencyLedgerRepository;
        _currentUser = currentUser;
        _unitOfWork = unitOfWork;
    }

    public async Task<Result<SeasonDto>> GetActiveSeasonAsync(CancellationToken cancellationToken = default)
    {
        var season = await _seasonRepository.GetCurrentActiveSeasonAsync(cancellationToken);
        if (season is null)
            return Result.Failure<SeasonDto>("Season.NotFound", "No active season currently running.");

        var tierDtos = season.RewardTiers.Select(t => new SeasonRewardTierDto(
            t.TierNumber,
            t.RequiredPoints,
            t.RewardType,
            t.Amount,
            t.ItemDefinitionId
        )).OrderBy(t => t.TierNumber).ToList();

        return Result.Success(new SeasonDto(
            season.Id,
            season.SeasonNumber,
            season.Title,
            season.StartDate,
            season.EndDate,
            season.IsActive,
            tierDtos));
    }

    public async Task<Result<UserSeasonProgressDto>> GetUserProgressAsync(CancellationToken cancellationToken = default)
    {
        if (!_currentUser.UserId.HasValue)
            return Result.Failure<UserSeasonProgressDto>("Auth.Unauthorized", "User is not authenticated.");

        var season = await _seasonRepository.GetCurrentActiveSeasonAsync(cancellationToken);
        if (season is null)
            return Result.Failure<UserSeasonProgressDto>("Season.NotFound", "No active season found.");

        var progress = await _seasonRepository.GetUserProgressAsync(_currentUser.UserId.Value, season.Id, cancellationToken);
        if (progress is null)
        {
            progress = UserSeasonProgress.Create(_currentUser.UserId.Value, season.Id);
            await _seasonRepository.AddUserProgressAsync(progress, cancellationToken);
            await _unitOfWork.SaveChangesAsync(cancellationToken);
        }

        return Result.Success(new UserSeasonProgressDto(
            progress.SeasonId,
            progress.CurrentPoints,
            progress.ClaimedTiers.ToList()));
    }

    public async Task<Result<bool>> ClaimTierRewardAsync(ClaimSeasonTierRequest request, CancellationToken cancellationToken = default)
    {
        if (!_currentUser.UserId.HasValue)
            return Result.Failure<bool>("Auth.Unauthorized", "User is not authenticated.");

        var userId = _currentUser.UserId.Value;
        var season = await _seasonRepository.GetByIdAsync(request.SeasonId, cancellationToken);
        if (season is null)
            return Result.Failure<bool>("Season.NotFound", "Season not found.");

        var tier = season.RewardTiers.FirstOrDefault(t => t.TierNumber == request.TierNumber);
        if (tier is null)
            return Result.Failure<bool>("Season.TierNotFound", "Requested tier does not exist in this season.");

        var progress = await _seasonRepository.GetUserProgressAsync(userId, season.Id, cancellationToken);
        if (progress is null || !progress.CanClaimTier(tier))
            return Result.Failure<bool>("Season.CannotClaim", "Insufficient points or tier already claimed.");

        // Claim in progress
        progress.ClaimTier(tier);
        await _seasonRepository.UpdateUserProgressAsync(progress, cancellationToken);

        // Grant reward
        var wallet = await _walletRepository.GetByUserIdAsync(userId, cancellationToken);
        if (wallet is not null)
        {
            if (tier.RewardType == RewardType.Coins)
            {
                wallet.AddCurrency(CurrencyType.Coins, tier.Amount);
                await _currencyLedgerRepository.AddEntryAsync(new CurrencyLedgerEntry(
                    userId,
                    CurrencyType.Coins,
                    tier.Amount,
                    $"Season Tier {tier.TierNumber} Reward: {season.Title}",
                    wallet.Coins), cancellationToken);
            }
            else if (tier.RewardType == RewardType.Gems)
            {
                wallet.AddCurrency(CurrencyType.Gems, tier.Amount);
                await _currencyLedgerRepository.AddEntryAsync(new CurrencyLedgerEntry(
                    userId,
                    CurrencyType.Gems,
                    tier.Amount,
                    $"Season Tier {tier.TierNumber} Reward: {season.Title}",
                    wallet.Gems), cancellationToken);
            }

            await _walletRepository.UpdateAsync(wallet, cancellationToken);
        }

        await _unitOfWork.SaveChangesAsync(cancellationToken);
        return Result.Success(true);
    }
}

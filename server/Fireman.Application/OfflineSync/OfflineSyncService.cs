using System.Text.Json;
using Fireman.Application.Common.Interfaces;
using Fireman.Contracts.Offline;
using Fireman.Domain.AntiCheat;
using Fireman.Domain.Characters;
using Fireman.Domain.Economy;
using Fireman.Domain.Missions;
using Fireman.Domain.Users;
using Fireman.Shared.Constants;
using Fireman.Shared.Enums;
using Fireman.Shared.Results;

namespace Fireman.Application.OfflineSync;

public interface IOfflineSyncService
{
    Task<Result<OfflineSyncResponse>> SynchronizeOfflineActionsAsync(OfflineSyncRequest request, CancellationToken cancellationToken = default);
}

public class OfflineSyncService : IOfflineSyncService
{
    private readonly IUserRepository _userRepository;
    private readonly ICharacterRepository _characterRepository;
    private readonly IWalletRepository _walletRepository;
    private readonly ICurrencyLedgerRepository _ledgerRepository;
    private readonly IAntiCheatRepository _antiCheatRepository;
    private readonly ICurrentUser _currentUser;
    private readonly IUnitOfWork _unitOfWork;

    public OfflineSyncService(
        IUserRepository userRepository,
        ICharacterRepository characterRepository,
        IWalletRepository walletRepository,
        ICurrencyLedgerRepository ledgerRepository,
        IAntiCheatRepository antiCheatRepository,
        ICurrentUser currentUser,
        IUnitOfWork unitOfWork)
    {
        _userRepository = userRepository;
        _characterRepository = characterRepository;
        _walletRepository = walletRepository;
        _ledgerRepository = ledgerRepository;
        _antiCheatRepository = antiCheatRepository;
        _currentUser = currentUser;
        _unitOfWork = unitOfWork;
    }

    public async Task<Result<OfflineSyncResponse>> SynchronizeOfflineActionsAsync(OfflineSyncRequest request, CancellationToken cancellationToken = default)
    {
        if (!_currentUser.UserId.HasValue)
            return Result.Failure<OfflineSyncResponse>("Auth.Unauthorized", "User is not authenticated.");

        var userId = _currentUser.UserId.Value;
        var user = await _userRepository.GetByIdAsync(userId, cancellationToken);
        var character = await _characterRepository.GetByUserIdAsync(userId, cancellationToken);
        var wallet = await _walletRepository.GetByUserIdAsync(userId, cancellationToken);

        if (user is null || character is null || wallet is null)
            return Result.Failure<OfflineSyncResponse>("User.NotFound", "User account, character or wallet not found.");

        var results = new List<OfflineActionResultDto>();
        int acceptedCount = 0;
        int rejectedCount = 0;

        foreach (var action in request.Actions)
        {
            // 1. Anti-Cheat: Validate timestamp sanity
            var timeDiff = DateTime.UtcNow - action.ClientTimestamp;
            if (action.ClientTimestamp > DateTime.UtcNow.AddMinutes(5)) // Clock skew / future time hack
            {
                await _antiCheatRepository.LogViolationAsync(new AntiCheatLog(
                    userId,
                    action.ActionType,
                    "Future timestamp detected during offline sync",
                    AntiCheatSeverity.High,
                    action.ClientTimestamp,
                    JsonSerializer.Serialize(new { action.ActionId, DiffMinutes = timeDiff.TotalMinutes })), cancellationToken);

                results.Add(new OfflineActionResultDto(action.ActionId, false, "Invalid client timestamp (in future).", null));
                rejectedCount++;
                continue;
            }

            // 2. Process recognized offline actions with validation
            if (action.ActionType.Equals("AddCoins", StringComparison.OrdinalIgnoreCase))
            {
                // Validate bounds
                if (int.TryParse(action.PayloadJson, out int amount))
                {
                    if (amount is > 0 and <= 500) // Plausible offline reward
                    {
                        wallet.AddCurrency(CurrencyType.Coins, amount);
                        await _ledgerRepository.AddEntryAsync(new CurrencyLedgerEntry(
                            userId,
                            CurrencyType.Coins,
                            amount,
                            $"Offline Sync: Batch {request.BatchId} Action {action.ActionId}",
                            wallet.Coins), cancellationToken);

                        results.Add(new OfflineActionResultDto(action.ActionId, true, null, new { NewBalance = wallet.Coins }));
                        acceptedCount++;
                    }
                    else
                    {
                        // Suspicious offline coin claim
                        await _antiCheatRepository.LogViolationAsync(new AntiCheatLog(
                            userId,
                            "AddCoins",
                            $"Suspicious offline coin claim of {amount} coins.",
                            AntiCheatSeverity.Critical,
                            action.ClientTimestamp,
                            action.PayloadJson), cancellationToken);

                        results.Add(new OfflineActionResultDto(action.ActionId, false, "Reward amount exceeds offline threshold.", null));
                        rejectedCount++;
                    }
                }
                else
                {
                    results.Add(new OfflineActionResultDto(action.ActionId, false, "Invalid payload format.", null));
                    rejectedCount++;
                }
            }
            else if (action.ActionType.Equals("AddXp", StringComparison.OrdinalIgnoreCase))
            {
                if (int.TryParse(action.PayloadJson, out int xp) && xp is > 0 and <= 1000)
                {
                    character.AddExperience(xp, out int newLevel);
                    results.Add(new OfflineActionResultDto(action.ActionId, true, null, new { CurrentLevel = newLevel }));
                    acceptedCount++;
                }
                else
                {
                    results.Add(new OfflineActionResultDto(action.ActionId, false, "Invalid XP amount or exceeded bounds.", null));
                    rejectedCount++;
                }
            }
            else
            {
                results.Add(new OfflineActionResultDto(action.ActionId, false, $"Unsupported offline action type: {action.ActionType}", null));
                rejectedCount++;
            }
        }

        if (acceptedCount > 0)
        {
            await _walletRepository.UpdateAsync(wallet, cancellationToken);
            await _characterRepository.UpdateAsync(character, cancellationToken);
            await _unitOfWork.SaveChangesAsync(cancellationToken);
        }

        return Result.Success(new OfflineSyncResponse(
            request.BatchId,
            rejectedCount == 0,
            request.Actions.Count,
            acceptedCount,
            rejectedCount,
            results));
    }
}

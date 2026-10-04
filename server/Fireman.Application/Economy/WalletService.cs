using Fireman.Application.Common.Interfaces;
using Fireman.Contracts.Economy;
using Fireman.Domain.Economy;
using Fireman.Shared.Results;

namespace Fireman.Application.Economy;

public interface IWalletService
{
    Task<Result<WalletSummaryDto>> GetWalletSummaryAsync(CancellationToken cancellationToken = default);
    Task<Result<IReadOnlyList<CurrencyLedgerDto>>> GetLedgerHistoryAsync(CancellationToken cancellationToken = default);
}

public class WalletService : IWalletService
{
    private readonly IWalletRepository _walletRepository;
    private readonly ICurrencyLedgerRepository _ledgerRepository;
    private readonly ICurrentUser _currentUser;

    public WalletService(
        IWalletRepository walletRepository,
        ICurrencyLedgerRepository ledgerRepository,
        ICurrentUser currentUser)
    {
        _walletRepository = walletRepository;
        _ledgerRepository = ledgerRepository;
        _currentUser = currentUser;
    }

    public async Task<Result<WalletSummaryDto>> GetWalletSummaryAsync(CancellationToken cancellationToken = default)
    {
        if (!_currentUser.UserId.HasValue)
            return Result.Failure<WalletSummaryDto>("Auth.Unauthorized", "User is not authenticated.");

        var userId = _currentUser.UserId.Value;
        var wallet = await _walletRepository.GetByUserIdAsync(userId, cancellationToken);
        if (wallet is null)
            return Result.Failure<WalletSummaryDto>("Wallet.NotFound", "Wallet not found.");

        var ledgerEntries = await _ledgerRepository.GetUserHistoryAsync(userId, cancellationToken);
        var ledgerDtos = ledgerEntries.Select(e => new CurrencyLedgerDto(
            e.Id,
            e.CurrencyType,
            e.Amount,
            e.Reason,
            e.BalanceAfter,
            e.CreatedAt
        )).ToList();

        var walletDto = new WalletDto(wallet.UserId, wallet.Coins, wallet.Gems);
        return Result.Success(new WalletSummaryDto(walletDto, ledgerDtos));
    }

    public async Task<Result<IReadOnlyList<CurrencyLedgerDto>>> GetLedgerHistoryAsync(CancellationToken cancellationToken = default)
    {
        if (!_currentUser.UserId.HasValue)
            return Result.Failure<IReadOnlyList<CurrencyLedgerDto>>("Auth.Unauthorized", "User is not authenticated.");

        var ledgerEntries = await _ledgerRepository.GetUserHistoryAsync(_currentUser.UserId.Value, cancellationToken);
        var dtos = ledgerEntries.Select(e => new CurrencyLedgerDto(
            e.Id,
            e.CurrencyType,
            e.Amount,
            e.Reason,
            e.BalanceAfter,
            e.CreatedAt
        )).ToList();

        return Result.Success<IReadOnlyList<CurrencyLedgerDto>>(dtos);
    }
}

using Fireman.Shared.Enums;

namespace Fireman.Contracts.Economy;

public record WalletDto(Guid UserId, int Coins, int Gems);

public record CurrencyLedgerDto(
    Guid Id,
    CurrencyType CurrencyType,
    int Amount,
    string Reason,
    int BalanceAfter,
    DateTime CreatedAt
);

public record WalletSummaryDto(
    WalletDto Wallet,
    IReadOnlyList<CurrencyLedgerDto> RecentTransactions
);

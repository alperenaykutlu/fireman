using Fireman.Domain.Common;
using Fireman.Shared.Enums;
using Fireman.Shared.Exceptions;

namespace Fireman.Domain.Economy;

public class CurrencyLedgerEntry : Entity<Guid>
{
    public Guid UserId { get; private set; }
    public CurrencyType CurrencyType { get; private set; }
    public int Amount { get; private set; }
    public string Reason { get; private set; }
    public int BalanceAfter { get; private set; }

    public CurrencyLedgerEntry(Guid userId, CurrencyType currencyType, int amount, string reason, int balanceAfter)
    {
        Id = Guid.NewGuid();
        UserId = userId;
        CurrencyType = currencyType;
        Amount = amount;
        Reason = reason;
        BalanceAfter = balanceAfter;
        CreatedAt = DateTime.UtcNow;
    }
}

public class Wallet : AggregateRoot<Guid>
{
    public Guid UserId { get; private set; }
    public int Coins { get; private set; }
    public int Gems { get; private set; }

    private Wallet() { }

    public static Wallet Create(Guid userId, int initialCoins = 500, int initialGems = 10)
    {
        return new Wallet
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Coins = initialCoins,
            Gems = initialGems,
            CreatedAt = DateTime.UtcNow
        };
    }

    public void AddCurrency(CurrencyType currency, int amount)
    {
        if (amount <= 0)
            throw new ValidationException("Amount added must be greater than zero.");

        if (currency == CurrencyType.Coins)
            Coins += amount;
        else if (currency == CurrencyType.Gems)
            Gems += amount;

        UpdatedAt = DateTime.UtcNow;
    }

    public void DeductCurrency(CurrencyType currency, int amount)
    {
        if (amount <= 0)
            throw new ValidationException("Amount deducted must be greater than zero.");

        if (currency == CurrencyType.Coins)
        {
            if (Coins < amount)
                throw new ValidationException($"Insufficient coins. Required: {amount}, Available: {Coins}");
            Coins -= amount;
        }
        else if (currency == CurrencyType.Gems)
        {
            if (Gems < amount)
                throw new ValidationException($"Insufficient gems. Required: {amount}, Available: {Gems}");
            Gems -= amount;
        }

        UpdatedAt = DateTime.UtcNow;
    }
}

public interface IWalletRepository
{
    Task<Wallet?> GetByUserIdAsync(Guid userId, CancellationToken cancellationToken = default);
    Task AddAsync(Wallet wallet, CancellationToken cancellationToken = default);
    Task UpdateAsync(Wallet wallet, CancellationToken cancellationToken = default);
}

public interface ICurrencyLedgerRepository
{
    Task AddEntryAsync(CurrencyLedgerEntry entry, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<CurrencyLedgerEntry>> GetUserHistoryAsync(Guid userId, CancellationToken cancellationToken = default);
}

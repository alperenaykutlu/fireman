using Fireman.Domain.Economy;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Fireman.Infrastructure.Persistence.Configurations;

public class CurrencyLedgerEntryConfiguration : IEntityTypeConfiguration<CurrencyLedgerEntry>
{
    public void Configure(EntityTypeBuilder<CurrencyLedgerEntry> builder)
    {
        builder.ToTable("currency_ledger_entries");

        builder.HasKey(c => c.Id);

        builder.Property(c => c.UserId).IsRequired();
        builder.HasIndex(c => c.UserId);

        builder.Property(c => c.CurrencyType).HasConversion<string>().HasMaxLength(50).IsRequired();
        builder.Property(c => c.Amount).IsRequired();
        builder.Property(c => c.Reason).HasMaxLength(255).IsRequired();
        builder.Property(c => c.BalanceAfter).IsRequired();
        builder.Property(c => c.CreatedAt).IsRequired();
    }
}

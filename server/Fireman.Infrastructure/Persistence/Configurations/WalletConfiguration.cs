using Fireman.Domain.Economy;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Fireman.Infrastructure.Persistence.Configurations;

public class WalletConfiguration : IEntityTypeConfiguration<Wallet>
{
    public void Configure(EntityTypeBuilder<Wallet> builder)
    {
        builder.ToTable("wallets");

        builder.HasKey(w => w.Id);

        builder.Property(w => w.UserId).IsRequired();
        builder.HasIndex(w => w.UserId).IsUnique();

        builder.Property(w => w.Coins).IsRequired();
        builder.Property(w => w.Gems).IsRequired();
        builder.Property(w => w.CreatedAt).IsRequired();
        builder.Property(w => w.UpdatedAt).IsRequired();
    }
}

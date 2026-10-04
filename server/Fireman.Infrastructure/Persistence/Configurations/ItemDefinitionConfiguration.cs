using Fireman.Domain.Inventory;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Fireman.Infrastructure.Persistence.Configurations;

public class ItemDefinitionConfiguration : IEntityTypeConfiguration<ItemDefinition>
{
    public void Configure(EntityTypeBuilder<ItemDefinition> builder)
    {
        builder.ToTable("item_definitions");

        builder.HasKey(i => i.Id);

        builder.Property(i => i.Name).HasMaxLength(150).IsRequired();
        builder.Property(i => i.Description).HasMaxLength(1000).IsRequired();
        builder.Property(i => i.Type).HasConversion<string>().HasMaxLength(50).IsRequired();
        builder.Property(i => i.Rarity).HasConversion<string>().HasMaxLength(50).IsRequired();
        builder.Property(i => i.CompatibleSlot).HasConversion<string>().HasMaxLength(50);
        builder.Property(i => i.Price).IsRequired();
        builder.Property(i => i.CurrencyType).HasConversion<string>().HasMaxLength(50).IsRequired();
        builder.Property(i => i.IsPurchasable).IsRequired();
        builder.Property(i => i.AssetId).HasMaxLength(255).IsRequired();
        builder.Property(i => i.CreatedAt).IsRequired();
    }
}

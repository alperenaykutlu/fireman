using Fireman.Domain.Inventory;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Fireman.Infrastructure.Persistence.Configurations;

public class InventoryItemConfiguration : IEntityTypeConfiguration<InventoryItem>
{
    public void Configure(EntityTypeBuilder<InventoryItem> builder)
    {
        builder.ToTable("inventory_items");

        builder.HasKey(i => i.Id);

        builder.Property(i => i.UserId).IsRequired();
        builder.Property(i => i.ItemDefinitionId).IsRequired();
        builder.HasIndex(i => new { i.UserId, i.ItemDefinitionId }).IsUnique();

        builder.Property(i => i.Quantity).IsRequired();
        builder.Property(i => i.AcquiredAt).IsRequired();
        builder.Property(i => i.CreatedAt).IsRequired();
        builder.Property(i => i.UpdatedAt);
    }
}

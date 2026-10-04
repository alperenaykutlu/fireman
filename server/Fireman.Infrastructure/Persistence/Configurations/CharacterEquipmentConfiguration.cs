using Fireman.Domain.Characters;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Fireman.Infrastructure.Persistence.Configurations;

public class CharacterEquipmentConfiguration : IEntityTypeConfiguration<CharacterEquipment>
{
    public void Configure(EntityTypeBuilder<CharacterEquipment> builder)
    {
        builder.ToTable("character_equipment");

        builder.HasKey(e => e.Id);

        builder.Property(e => e.CharacterId).IsRequired();
        builder.Property(e => e.Slot).HasConversion<string>().HasMaxLength(50).IsRequired();
        builder.Property(e => e.ItemDefinitionId).IsRequired();
        builder.Property(e => e.EquippedAt).IsRequired();

        builder.HasIndex(e => new { e.CharacterId, e.Slot }).IsUnique();
    }
}

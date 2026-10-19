using Fireman.Domain.Characters;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Fireman.Infrastructure.Persistence.Configurations;

public class CharacterCustomizationConfiguration : IEntityTypeConfiguration<CharacterCustomization>
{
    public void Configure(EntityTypeBuilder<CharacterCustomization> builder)
    {
        builder.ToTable("character_customizations");
        builder.HasKey(x => x.ProfileId);
        builder.Property(x => x.Gender).HasMaxLength(10).IsRequired();
        builder.Property(x => x.Hat).HasMaxLength(80).IsRequired();
        builder.Property(x => x.Suit).HasMaxLength(80).IsRequired();
        builder.Property(x => x.Accessory).HasMaxLength(80).IsRequired();
        builder.Property(x => x.SkinColorValue).IsRequired();
        builder.Property(x => x.SuitColorValue).IsRequired();
        builder.Property(x => x.UpdatedAt).IsRequired();
    }
}

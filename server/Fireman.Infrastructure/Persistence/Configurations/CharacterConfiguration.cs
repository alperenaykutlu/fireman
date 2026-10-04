using Fireman.Domain.Characters;
using Fireman.Shared.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Fireman.Infrastructure.Persistence.Configurations;

public class CharacterConfiguration : IEntityTypeConfiguration<Character>
{
    public void Configure(EntityTypeBuilder<Character> builder)
    {
        builder.ToTable("characters");

        builder.HasKey(c => c.Id);

        builder.Property(c => c.UserId).IsRequired();
        builder.HasIndex(c => c.UserId);

        builder.Property(c => c.Name).HasMaxLength(100).IsRequired();
        builder.Property(c => c.Gender).HasConversion<string>().HasMaxLength(20).IsRequired();
        builder.Property(c => c.Level).IsRequired();
        builder.Property(c => c.Experience).IsRequired();
        builder.Property(c => c.CreatedAt).IsRequired();
        builder.Property(c => c.UpdatedAt);

        builder.HasMany(c => c.EquippedItems)
            .WithOne()
            .HasForeignKey(e => e.CharacterId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.Navigation(c => c.EquippedItems).UsePropertyAccessMode(PropertyAccessMode.Field);
    }
}

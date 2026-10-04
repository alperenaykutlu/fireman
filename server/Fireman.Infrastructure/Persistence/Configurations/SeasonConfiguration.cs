using Fireman.Domain.Seasons;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Fireman.Infrastructure.Persistence.Configurations;

public class SeasonConfiguration : IEntityTypeConfiguration<Season>
{
    public void Configure(EntityTypeBuilder<Season> builder)
    {
        builder.ToTable("seasons");

        builder.HasKey(s => s.Id);

        builder.Property(s => s.SeasonNumber).IsRequired();
        builder.HasIndex(s => s.SeasonNumber).IsUnique();

        builder.Property(s => s.Title).HasMaxLength(150).IsRequired();
        builder.Property(s => s.StartDate).IsRequired();
        builder.Property(s => s.EndDate).IsRequired();
        builder.Property(s => s.CreatedAt).IsRequired();

        builder.HasMany(s => s.RewardTiers)
            .WithOne()
            .HasForeignKey(t => t.SeasonId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.Navigation(s => s.RewardTiers).UsePropertyAccessMode(PropertyAccessMode.Field);
    }
}

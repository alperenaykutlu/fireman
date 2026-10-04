using Fireman.Domain.Missions;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Fireman.Infrastructure.Persistence.Configurations;

public class MissionConfiguration : IEntityTypeConfiguration<Mission>
{
    public void Configure(EntityTypeBuilder<Mission> builder)
    {
        builder.ToTable("missions");

        builder.HasKey(m => m.Id);

        builder.Property(m => m.Title).HasMaxLength(150).IsRequired();
        builder.Property(m => m.Description).HasMaxLength(1000).IsRequired();
        builder.Property(m => m.Type).HasConversion<string>().HasMaxLength(50).IsRequired();
        builder.Property(m => m.RequiredLevel).IsRequired();
        builder.Property(m => m.BaseRewardCoins).IsRequired();
        builder.Property(m => m.BaseRewardXp).IsRequired();
        builder.Property(m => m.TargetScore).IsRequired();
        builder.Property(m => m.CreatedAt).IsRequired();
    }
}

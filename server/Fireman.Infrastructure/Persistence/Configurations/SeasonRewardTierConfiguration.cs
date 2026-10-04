using Fireman.Domain.Seasons;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Fireman.Infrastructure.Persistence.Configurations;

public class SeasonRewardTierConfiguration : IEntityTypeConfiguration<SeasonRewardTier>
{
    public void Configure(EntityTypeBuilder<SeasonRewardTier> builder)
    {
        builder.ToTable("season_reward_tiers");

        builder.HasKey(t => t.Id);

        builder.Property(t => t.SeasonId).IsRequired();
        builder.Property(t => t.TierNumber).IsRequired();
        builder.HasIndex(t => new { t.SeasonId, t.TierNumber }).IsUnique();

        builder.Property(t => t.RequiredPoints).IsRequired();
        builder.Property(t => t.RewardType).HasConversion<string>().HasMaxLength(50).IsRequired();
        builder.Property(t => t.Amount).IsRequired();
        builder.Property(t => t.ItemDefinitionId);
        builder.Property(t => t.CreatedAt).IsRequired();
    }
}

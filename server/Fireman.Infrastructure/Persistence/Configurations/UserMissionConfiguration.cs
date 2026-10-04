using Fireman.Domain.Missions;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Fireman.Infrastructure.Persistence.Configurations;

public class UserMissionConfiguration : IEntityTypeConfiguration<UserMission>
{
    public void Configure(EntityTypeBuilder<UserMission> builder)
    {
        builder.ToTable("user_missions");

        builder.HasKey(um => um.Id);

        builder.Property(um => um.UserId).IsRequired();
        builder.Property(um => um.MissionId).IsRequired();
        builder.HasIndex(um => new { um.UserId, um.MissionId });

        builder.Property(um => um.Status).HasConversion<string>().HasMaxLength(50).IsRequired();
        builder.Property(um => um.CurrentScore).IsRequired();
        builder.Property(um => um.TargetScore).IsRequired();
        builder.Property(um => um.StartedAt);
        builder.Property(um => um.CompletedAt);
        builder.Property(um => um.CreatedAt).IsRequired();
        builder.Property(um => um.UpdatedAt).IsRequired();
    }
}

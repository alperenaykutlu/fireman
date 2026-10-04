using Fireman.Domain.Social;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Fireman.Infrastructure.Persistence.Configurations;

public class PlayerReportConfiguration : IEntityTypeConfiguration<PlayerReport>
{
    public void Configure(EntityTypeBuilder<PlayerReport> builder)
    {
        builder.ToTable("player_reports");

        builder.HasKey(r => r.Id);

        builder.Property(r => r.ReporterUserId).IsRequired();
        builder.Property(r => r.ReportedUserId).IsRequired();
        builder.HasIndex(r => r.ReportedUserId);

        builder.Property(r => r.Reason).HasConversion<string>().HasMaxLength(50).IsRequired();
        builder.Property(r => r.Description).HasMaxLength(1000).IsRequired();
        builder.Property(r => r.CreatedAt).IsRequired();
    }
}

using Fireman.Domain.AntiCheat;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Fireman.Infrastructure.Persistence.Configurations;

public class AntiCheatLogConfiguration : IEntityTypeConfiguration<AntiCheatLog>
{
    public void Configure(EntityTypeBuilder<AntiCheatLog> builder)
    {
        builder.ToTable("anti_cheat_logs");

        builder.HasKey(a => a.Id);

        builder.Property(a => a.UserId).IsRequired();
        builder.HasIndex(a => a.UserId);

        builder.Property(a => a.Action).HasMaxLength(100).IsRequired();
        builder.Property(a => a.Reason).HasMaxLength(500).IsRequired();
        builder.Property(a => a.Severity).HasConversion<string>().HasMaxLength(50).IsRequired();
        builder.Property(a => a.ClientTimestamp).IsRequired();
        builder.Property(a => a.ServerTimestamp).IsRequired();
        builder.Property(a => a.MetadataJson);
        builder.Property(a => a.CreatedAt).IsRequired();
    }
}

using Fireman.Domain.Matches;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Fireman.Infrastructure.Persistence.Configurations;

public class MatchConfiguration : IEntityTypeConfiguration<Match>
{
    public void Configure(EntityTypeBuilder<Match> builder)
    {
        builder.ToTable("matches");

        builder.HasKey(m => m.Id);

        builder.Property(m => m.Type).HasConversion<string>().HasMaxLength(50).IsRequired();
        builder.Property(m => m.Status).HasConversion<string>().HasMaxLength(50).IsRequired();
        builder.Property(m => m.HostUserId).IsRequired();
        builder.Property(m => m.MaxPlayers).IsRequired();
        builder.Property(m => m.CreatedAt).IsRequired();
        builder.Property(m => m.StartedAt);
        builder.Property(m => m.FinishedAt);

        builder.HasMany(m => m.Players)
            .WithOne()
            .HasForeignKey(p => p.MatchId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.Navigation(m => m.Players).UsePropertyAccessMode(PropertyAccessMode.Field);
    }
}

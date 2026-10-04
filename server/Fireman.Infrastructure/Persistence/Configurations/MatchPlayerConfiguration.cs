using Fireman.Domain.Matches;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Fireman.Infrastructure.Persistence.Configurations;

public class MatchPlayerConfiguration : IEntityTypeConfiguration<MatchPlayer>
{
    public void Configure(EntityTypeBuilder<MatchPlayer> builder)
    {
        builder.ToTable("match_players");

        builder.HasKey(p => p.Id);

        builder.Property(p => p.MatchId).IsRequired();
        builder.Property(p => p.UserId).IsRequired();
        builder.HasIndex(p => new { p.MatchId, p.UserId }).IsUnique();

        builder.Property(p => p.Username).HasMaxLength(50).IsRequired();
        builder.Property(p => p.Score).IsRequired();
        builder.Property(p => p.Rescues).IsRequired();
        builder.Property(p => p.IsReady).IsRequired();
        builder.Property(p => p.CreatedAt).IsRequired();
    }
}

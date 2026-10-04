using System.Text.Json;
using Fireman.Domain.Seasons;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Fireman.Infrastructure.Persistence.Configurations;

public class UserSeasonProgressConfiguration : IEntityTypeConfiguration<UserSeasonProgress>
{
    public void Configure(EntityTypeBuilder<UserSeasonProgress> builder)
    {
        builder.ToTable("user_season_progresses");

        builder.HasKey(p => p.Id);

        builder.Property(p => p.UserId).IsRequired();
        builder.Property(p => p.SeasonId).IsRequired();
        builder.HasIndex(p => new { p.UserId, p.SeasonId }).IsUnique();

        builder.Property(p => p.CurrentPoints).IsRequired();
        builder.Property(p => p.CreatedAt).IsRequired();
        builder.Property(p => p.UpdatedAt);

        builder.Property(p => p.ClaimedTiers)
            .HasConversion(
                v => JsonSerializer.Serialize(v, (JsonSerializerOptions?)null),
                v => JsonSerializer.Deserialize<HashSet<int>>(v, (JsonSerializerOptions?)null) ?? new HashSet<int>())
            .HasColumnType("text")
            .IsRequired();
    }
}

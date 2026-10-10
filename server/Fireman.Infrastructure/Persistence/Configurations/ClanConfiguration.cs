using Fireman.Domain.Social;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Fireman.Infrastructure.Persistence.Configurations;

public class ClanConfiguration : IEntityTypeConfiguration<Clan>
{
    public void Configure(EntityTypeBuilder<Clan> builder)
    {
        builder.ToTable("clans");

        builder.HasKey(c => c.Id);
        builder.Property(c => c.Id).HasColumnName("id");

        builder.Property(c => c.Name).HasColumnName("name").HasMaxLength(50).IsRequired();
        builder.Property(c => c.Tag).HasColumnName("tag").HasMaxLength(10).IsRequired();
        builder.Property(c => c.Description).HasColumnName("description").HasMaxLength(500);
        builder.Property(c => c.BadgeIcon).HasColumnName("badge_icon").HasMaxLength(50).IsRequired();
        builder.Property(c => c.Level).HasColumnName("level").IsRequired();
        builder.Property(c => c.ExperiencePoints).HasColumnName("experience_points").IsRequired();
        builder.Property(c => c.RequiredTrophies).HasColumnName("required_trophies").IsRequired();
        builder.Property(c => c.IsOpen).HasColumnName("is_open").IsRequired();
        builder.Property(c => c.CreatedAt).HasColumnName("created_at").IsRequired();

        builder.HasIndex(c => c.Tag).IsUnique();

        builder.HasMany(c => c.Members)
            .WithOne()
            .HasForeignKey(m => m.ClanId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}

public class ClanMemberConfiguration : IEntityTypeConfiguration<ClanMember>
{
    public void Configure(EntityTypeBuilder<ClanMember> builder)
    {
        builder.ToTable("clan_members");

        builder.HasKey(m => m.Id);
        builder.Property(m => m.Id).HasColumnName("id");

        builder.Property(m => m.ClanId).HasColumnName("clan_id").IsRequired();
        builder.Property(m => m.UserId).HasColumnName("user_id").IsRequired();
        builder.Property(m => m.Role).HasColumnName("role").IsRequired();
        builder.Property(m => m.JoinedAt).HasColumnName("joined_at").IsRequired();

        builder.HasIndex(m => new { m.ClanId, m.UserId }).IsUnique();
        builder.HasIndex(m => m.UserId);
    }
}

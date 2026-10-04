using Fireman.Domain.Social;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Fireman.Infrastructure.Persistence.Configurations;

public class FriendshipConfiguration : IEntityTypeConfiguration<Friendship>
{
    public void Configure(EntityTypeBuilder<Friendship> builder)
    {
        builder.ToTable("friendships");

        builder.HasKey(f => f.Id);

        builder.Property(f => f.UserId).IsRequired();
        builder.Property(f => f.FriendUserId).IsRequired();
        builder.HasIndex(f => new { f.UserId, f.FriendUserId }).IsUnique();

        builder.Property(f => f.Status).HasConversion<string>().HasMaxLength(50).IsRequired();
        builder.Property(f => f.CreatedAt).IsRequired();
        builder.Property(f => f.UpdatedAt);
    }
}

using Fireman.Domain.Users;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Fireman.Infrastructure.Persistence.Configurations;

public class UserConfiguration : IEntityTypeConfiguration<User>
{
    public void Configure(EntityTypeBuilder<User> builder)
    {
        builder.ToTable("users");

        builder.HasKey(u => u.Id);

        builder.Property(u => u.Username)
            .HasConversion(u => u.Value, v => Username.Create(v))
            .HasMaxLength(30)
            .IsRequired();

        builder.HasIndex(u => u.Username).IsUnique();

        builder.Property(u => u.Email)
            .HasMaxLength(255)
            .IsRequired();

        builder.HasIndex(u => u.Email).IsUnique();

        builder.Property(u => u.PasswordHash)
            .HasMaxLength(500)
            .IsRequired();

        builder.Property(u => u.Role)
            .HasConversion<string>()
            .HasMaxLength(50)
            .IsRequired();

        builder.Property(u => u.Status)
            .HasConversion<string>()
            .HasMaxLength(50)
            .IsRequired();

        builder.Property(u => u.CreatedAt).IsRequired();
        builder.Property(u => u.UpdatedAt).IsRequired();

        builder.OwnsMany(u => u.RefreshTokens, rb =>
        {
            rb.ToTable("user_refresh_tokens");
            rb.WithOwner().HasForeignKey("UserId");
            rb.Property<int>("Id").ValueGeneratedOnAdd();
            rb.HasKey("Id");
            rb.Property(t => t.TokenHash).HasMaxLength(500).IsRequired();
            rb.Property(t => t.ExpiresAt).IsRequired();
            rb.Property(t => t.CreatedAt).IsRequired();
            rb.Property(t => t.RevokedAt);
            rb.Property(t => t.ReplacedByToken).HasMaxLength(500);
        });
    }
}

using Fireman.Domain.Notifications;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Fireman.Infrastructure.Persistence.Configurations;

public class InAppNotificationConfiguration : IEntityTypeConfiguration<InAppNotification>
{
    public void Configure(EntityTypeBuilder<InAppNotification> builder)
    {
        builder.ToTable("in_app_notifications");

        builder.HasKey(n => n.Id);

        builder.Property(n => n.UserId).IsRequired();
        builder.HasIndex(n => n.UserId);

        builder.Property(n => n.Title).HasMaxLength(150).IsRequired();
        builder.Property(n => n.Message).HasMaxLength(1000).IsRequired();
        builder.Property(n => n.Type).HasConversion<string>().HasMaxLength(50).IsRequired();
        builder.Property(n => n.IsRead).IsRequired();
        builder.Property(n => n.CreatedAt).IsRequired();
        builder.Property(n => n.UpdatedAt);
    }
}

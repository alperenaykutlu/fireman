using Fireman.Domain.Social;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Fireman.Infrastructure.Persistence.Configurations;

public sealed class DirectMessageConfiguration : IEntityTypeConfiguration<DirectMessage>
{
    public void Configure(EntityTypeBuilder<DirectMessage> builder)
    {
        builder.ToTable("direct_messages");
        builder.HasKey(message => message.Id);
        builder.Property(message => message.SenderUserId).IsRequired();
        builder.Property(message => message.RecipientUserId).IsRequired();
        builder.Property(message => message.SenderUsername).HasMaxLength(50).IsRequired();
        builder.Property(message => message.Body).HasMaxLength(500).IsRequired();
        builder.Property(message => message.CreatedAt).IsRequired();
        builder.HasIndex(message => new { message.SenderUserId, message.RecipientUserId, message.CreatedAt });
    }
}

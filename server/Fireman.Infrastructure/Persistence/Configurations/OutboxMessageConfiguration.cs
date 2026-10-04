using Fireman.Application.Common.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Fireman.Infrastructure.Persistence.Configurations;

public class OutboxMessageConfiguration : IEntityTypeConfiguration<OutboxMessage>
{
    public void Configure(EntityTypeBuilder<OutboxMessage> builder)
    {
        builder.ToTable("outbox_messages");

        builder.HasKey(o => o.Id);

        builder.Property(o => o.EventType).HasMaxLength(150).IsRequired();
        builder.Property(o => o.PayloadJson).IsRequired();
        builder.Property(o => o.OccurredOn).IsRequired();
        builder.Property(o => o.ProcessedOn);
        builder.Property(o => o.Error).HasMaxLength(1000);

        builder.HasIndex(o => o.ProcessedOn);
    }
}

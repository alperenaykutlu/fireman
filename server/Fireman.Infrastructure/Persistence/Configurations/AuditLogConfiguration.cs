using Fireman.Domain.Audit;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Fireman.Infrastructure.Persistence.Configurations;

public class AuditLogConfiguration : IEntityTypeConfiguration<AuditLog>
{
    public void Configure(EntityTypeBuilder<AuditLog> builder)
    {
        builder.ToTable("audit_logs");

        builder.HasKey(a => a.Id);

        builder.Property(a => a.ActorUserId).IsRequired();
        builder.HasIndex(a => a.ActorUserId);

        builder.Property(a => a.Action).HasMaxLength(100).IsRequired();
        builder.Property(a => a.TargetEntity).HasMaxLength(100).IsRequired();
        builder.Property(a => a.TargetId).HasMaxLength(100);
        builder.Property(a => a.Details).HasMaxLength(2000).IsRequired();
        builder.Property(a => a.CorrelationId).HasMaxLength(100);
        builder.Property(a => a.CreatedAt).IsRequired();
    }
}

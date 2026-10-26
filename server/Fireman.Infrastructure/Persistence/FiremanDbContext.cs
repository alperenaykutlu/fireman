using Fireman.Application.Common.Interfaces;
using Fireman.Domain.AntiCheat;
using Fireman.Domain.Audit;
using Fireman.Domain.Characters;
using Fireman.Domain.Economy;
using Fireman.Domain.Inventory;
using Fireman.Domain.Matches;
using Fireman.Domain.Missions;
using Fireman.Domain.Notifications;
using Fireman.Domain.Seasons;
using Fireman.Domain.Social;
using Fireman.Domain.Users;
using Microsoft.EntityFrameworkCore;

namespace Fireman.Infrastructure.Persistence;

public class FiremanDbContext : DbContext
{
    public FiremanDbContext(DbContextOptions<FiremanDbContext> options)
        : base(options)
    {
    }

    public DbSet<User> Users => Set<User>();
    public DbSet<Character> Characters => Set<Character>();
    public DbSet<CharacterEquipment> CharacterEquipments => Set<CharacterEquipment>();
    public DbSet<CharacterCustomization> CharacterCustomizations => Set<CharacterCustomization>();
    public DbSet<ItemDefinition> ItemDefinitions => Set<ItemDefinition>();
    public DbSet<InventoryItem> InventoryItems => Set<InventoryItem>();
    public DbSet<Mission> Missions => Set<Mission>();
    public DbSet<UserMission> UserMissions => Set<UserMission>();
    public DbSet<Match> Matches => Set<Match>();
    public DbSet<MatchPlayer> MatchPlayers => Set<MatchPlayer>();
    public DbSet<Wallet> Wallets => Set<Wallet>();
    public DbSet<CurrencyLedgerEntry> CurrencyLedgerEntries => Set<CurrencyLedgerEntry>();
    public DbSet<AuditLog> AuditLogs => Set<AuditLog>();
    public DbSet<AntiCheatLog> AntiCheatLogs => Set<AntiCheatLog>();
    public DbSet<OutboxMessage> OutboxMessages => Set<OutboxMessage>();
    public DbSet<Season> Seasons => Set<Season>();
    public DbSet<SeasonRewardTier> SeasonRewardTiers => Set<SeasonRewardTier>();
    public DbSet<UserSeasonProgress> UserSeasonProgresses => Set<UserSeasonProgress>();
    public DbSet<Friendship> Friendships => Set<Friendship>();
    public DbSet<DirectMessage> DirectMessages => Set<DirectMessage>();
    public DbSet<Clan> Clans => Set<Clan>();
    public DbSet<ClanMember> ClanMembers => Set<ClanMember>();
    public DbSet<PlayerReport> PlayerReports => Set<PlayerReport>();
    public DbSet<InAppNotification> InAppNotifications => Set<InAppNotification>();
    public DbSet<DocumentRecord> Documents => Set<DocumentRecord>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(FiremanDbContext).Assembly);
        modelBuilder.Entity<DocumentRecord>(entity =>
        {
            entity.ToTable("ApplicationDocuments");
            entity.HasKey(document => new { document.Collection, document.Id });
            entity.Property(document => document.Collection).HasMaxLength(80);
            entity.Property(document => document.Id).HasMaxLength(128);
            entity.Property(document => document.Payload).IsRequired();
            entity.Property(document => document.IndexedFields).HasColumnType("jsonb").IsRequired();
        });
    }
}

public sealed class DocumentRecord
{
    public string Collection { get; set; } = string.Empty;
    public string Id { get; set; } = string.Empty;
    public string Payload { get; set; } = string.Empty;
    public string IndexedFields { get; set; } = "{}";
}

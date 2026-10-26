using System.Collections.Concurrent;
using Fireman.Application.Common.Interfaces;
using Fireman.Domain.AntiCheat;
using Fireman.Domain.Characters;
using Fireman.Domain.Economy;
using Fireman.Domain.Inventory;
using Fireman.Domain.Matches;
using Fireman.Domain.Missions;
using Fireman.Domain.Users;
using Fireman.Domain.Social;
using Fireman.Shared.Enums;

namespace Fireman.Infrastructure.Persistence;

public class InMemoryDbContext
{
    public ConcurrentDictionary<Guid, User> Users { get; } = new();
    public ConcurrentDictionary<Guid, Character> Characters { get; } = new();
    public ConcurrentDictionary<Guid, InventoryItem> InventoryItems { get; } = new();
    public ConcurrentDictionary<Guid, ItemDefinition> ItemDefinitions { get; } = new();
    public ConcurrentDictionary<Guid, Mission> Missions { get; } = new();
    public ConcurrentDictionary<Guid, UserMission> UserMissions { get; } = new();
    public ConcurrentDictionary<Guid, Match> Matches { get; } = new();
    public ConcurrentDictionary<Guid, DirectMessage> DirectMessages { get; } = new();
    public ConcurrentDictionary<Guid, Friendship> Friendships { get; } = new();
    public ConcurrentDictionary<Guid, Wallet> Wallets { get; } = new();
    public List<CurrencyLedgerEntry> CurrencyLedger { get; } = new();
    public List<AntiCheatLog> AntiCheatLogs { get; } = new();
    public List<OutboxMessage> OutboxMessages { get; } = new();

    public InMemoryDbContext()
    {
        SeedData();
    }

    private void SeedData()
    {
        // Starter Item Definitions (Cosmetics & Gear)
        var helmet = new ItemDefinition(
            Guid.Parse("11111111-1111-1111-1111-111111111111"),
            "Chief Fire Helmet",
            "Heat-resistant protective helmet with safety visor",
            ItemType.Cosmetic,
            ItemRarity.Uncommon,
            CharacterSlot.Hat,
            250,
            CurrencyType.Coins,
            true,
            "helmet_chief_red");

        var coat = new ItemDefinition(
            Guid.Parse("22222222-2222-2222-2222-222222222222"),
            "Turnout Coat Pro",
            "High-visibility reflective bunker coat for hazardous operations",
            ItemType.Cosmetic,
            ItemRarity.Rare,
            CharacterSlot.Top,
            500,
            CurrencyType.Coins,
            true,
            "turnout_coat_pro");

        var boots = new ItemDefinition(
            Guid.Parse("33333333-3333-3333-3333-333333333333"),
            "Steel-Toe Bunker Boots",
            "Heavy-duty fire boots with slip and heat resistance",
            ItemType.Cosmetic,
            ItemRarity.Common,
            CharacterSlot.Shoes,
            150,
            CurrencyType.Coins,
            true,
            "boots_steel_toe");

        var oxygenTank = new ItemDefinition(
            Guid.Parse("44444444-4444-4444-4444-444444444444"),
            "SCBA Breathing Apparatus",
            "Self-contained compressed air breathing apparatus",
            ItemType.Equipment,
            ItemRarity.Epic,
            CharacterSlot.BackItem,
            1200,
            CurrencyType.Coins,
            true,
            "scba_tank_yellow");

        var legendaryAxe = new ItemDefinition(
            Guid.Parse("55555555-5555-5555-5555-555555555555"),
            "Golden Halligan Rescue Bar",
            "Exclusive golden rescue and breach tool for elite firefighters",
            ItemType.Equipment,
            ItemRarity.Legendary,
            CharacterSlot.Accessory,
            50,
            CurrencyType.Gems,
            true,
            "halligan_golden");

        ItemDefinitions.TryAdd(helmet.Id, helmet);
        ItemDefinitions.TryAdd(coat.Id, coat);
        ItemDefinitions.TryAdd(boots.Id, boots);
        ItemDefinitions.TryAdd(oxygenTank.Id, oxygenTank);
        ItemDefinitions.TryAdd(legendaryAxe.Id, legendaryAxe);

        // Seed Missions
        var m1 = new Mission(
            Guid.Parse("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"),
            "Suburban Kitchen Flare-Up",
            "Extinguish a stove grease fire and ventilate smoke",
            MissionType.Rescue,
            requiredLevel: 1,
            baseRewardCoins: 100,
            baseRewardXp: 150,
            targetScore: 500);

        var m2 = new Mission(
            Guid.Parse("bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"),
            "Apartment Complex Evacuation",
            "Multi-story apartment fire. Locate and rescue stranded occupants",
            MissionType.Rescue,
            requiredLevel: 2,
            baseRewardCoins: 250,
            baseRewardXp: 350,
            targetScore: 1200);

        var m3 = new Mission(
            Guid.Parse("cccccccc-cccc-cccc-cccc-cccccccccccc"),
            "Industrial Chemical Hazmat Incident",
            "Contain hazardous runoff and suppress chemical storage blaze",
            MissionType.HazardContainment,
            requiredLevel: 3,
            baseRewardCoins: 500,
            baseRewardXp: 800,
            targetScore: 2500);

        Missions.TryAdd(m1.Id, m1);
        Missions.TryAdd(m2.Id, m2);
        Missions.TryAdd(m3.Id, m3);
    }
}

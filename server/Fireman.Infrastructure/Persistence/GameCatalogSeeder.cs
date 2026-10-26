using Fireman.Application.Common.Interfaces;
using Fireman.Domain.Inventory;
using Fireman.Domain.Missions;
using Fireman.Shared.Enums;
using Microsoft.Extensions.Hosting;

namespace Fireman.Infrastructure.Persistence;

/// <summary>Seeds starter catalog data on every persistence provider using stable IDs.</summary>
public sealed class GameCatalogSeeder(IDocumentDatabase database) : IHostedService
{
    public async Task StartAsync(CancellationToken cancellationToken)
    {
        var items = new[]
        {
            new ItemDefinition(Guid.Parse("11111111-1111-1111-1111-111111111111"), "Chief Fire Helmet", "Heat-resistant protective helmet with safety visor", ItemType.Cosmetic, ItemRarity.Uncommon, CharacterSlot.Hat, 250, CurrencyType.Coins, true, "helmet_chief_red"),
            new ItemDefinition(Guid.Parse("22222222-2222-2222-2222-222222222222"), "Turnout Coat Pro", "High-visibility reflective bunker coat for hazardous operations", ItemType.Cosmetic, ItemRarity.Rare, CharacterSlot.Top, 500, CurrencyType.Coins, true, "turnout_coat_pro"),
            new ItemDefinition(Guid.Parse("33333333-3333-3333-3333-333333333333"), "Steel-Toe Bunker Boots", "Heavy-duty fire boots with slip and heat resistance", ItemType.Cosmetic, ItemRarity.Common, CharacterSlot.Shoes, 150, CurrencyType.Coins, true, "boots_steel_toe"),
            new ItemDefinition(Guid.Parse("44444444-4444-4444-4444-444444444444"), "SCBA Breathing Apparatus", "Self-contained compressed air breathing apparatus", ItemType.Equipment, ItemRarity.Epic, CharacterSlot.BackItem, 1200, CurrencyType.Coins, true, "scba_tank_yellow"),
            new ItemDefinition(Guid.Parse("55555555-5555-5555-5555-555555555555"), "Golden Halligan Rescue Bar", "Exclusive golden rescue and breach tool for elite firefighters", ItemType.Equipment, ItemRarity.Legendary, CharacterSlot.Accessory, 50, CurrencyType.Gems, true, "halligan_golden")
        };
        foreach (var item in items)
            await database.TryCreateAsync("itemDefinitions", item.Id.ToString(), item, cancellationToken);

        var missions = new[]
        {
            new Mission(Guid.Parse("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"), "Suburban Kitchen Flare-Up", "Extinguish a stove grease fire and ventilate smoke", MissionType.Rescue, 1, 100, 150, 500),
            new Mission(Guid.Parse("bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"), "Apartment Complex Evacuation", "Multi-story apartment fire. Locate and rescue stranded occupants", MissionType.Rescue, 2, 250, 350, 1200),
            new Mission(Guid.Parse("cccccccc-cccc-cccc-cccc-cccccccccccc"), "Industrial Chemical Hazmat Incident", "Contain hazardous runoff and suppress chemical storage blaze", MissionType.HazardContainment, 3, 500, 800, 2500)
        };
        foreach (var mission in missions)
            await database.TryCreateAsync("missions", mission.Id.ToString(), mission, cancellationToken);
    }

    public Task StopAsync(CancellationToken cancellationToken) => Task.CompletedTask;
}

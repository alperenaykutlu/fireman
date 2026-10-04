using Fireman.Domain.Common;
using Fireman.Shared.Enums;

namespace Fireman.Domain.Inventory;

public class ItemDefinition : Entity<Guid>
{
    public string Name { get; private set; } = string.Empty;
    public string Description { get; private set; } = string.Empty;
    public ItemType Type { get; private set; }
    public ItemRarity Rarity { get; private set; }
    public CharacterSlot? CompatibleSlot { get; private set; }
    public int Price { get; private set; }
    public CurrencyType CurrencyType { get; private set; }
    public bool IsPurchasable { get; private set; }
    public string AssetId { get; private set; } = string.Empty;

    private ItemDefinition() { }

    public ItemDefinition(
        Guid id,
        string name,
        string description,
        ItemType type,
        ItemRarity rarity,
        CharacterSlot? compatibleSlot,
        int price,
        CurrencyType currencyType,
        bool isPurchasable,
        string assetId)
    {
        Id = id;
        Name = name;
        Description = description;
        Type = type;
        Rarity = rarity;
        CompatibleSlot = compatibleSlot;
        Price = price;
        CurrencyType = currencyType;
        IsPurchasable = isPurchasable;
        AssetId = assetId;
        CreatedAt = DateTime.UtcNow;
    }
}

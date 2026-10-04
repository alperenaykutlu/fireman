using Fireman.Shared.Enums;

namespace Fireman.Contracts.Inventory;

public record ItemDefinitionDto(
    Guid Id,
    string Name,
    string Description,
    ItemType Type,
    ItemRarity Rarity,
    CharacterSlot? CompatibleSlot,
    int Price,
    CurrencyType CurrencyType,
    bool IsPurchasable,
    string AssetId
);

public record InventoryItemDto(
    Guid Id,
    Guid ItemDefinitionId,
    string Name,
    ItemType Type,
    ItemRarity Rarity,
    CharacterSlot? CompatibleSlot,
    int Quantity,
    DateTime AcquiredAt
);

public record BuyItemRequest(Guid ItemDefinitionId, int Quantity);

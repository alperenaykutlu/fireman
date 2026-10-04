using Fireman.Shared.Enums;

namespace Fireman.Contracts.Characters;

public record EquippedItemDto(
    CharacterSlot Slot,
    Guid ItemDefinitionId,
    string ItemName,
    string AssetId,
    DateTime EquippedAt
);

public record CharacterDto(
    Guid Id,
    Guid UserId,
    string Name,
    CharacterGender Gender,
    int Level,
    long Experience,
    List<EquippedItemDto> EquippedItems
);

public record CreateCharacterRequest(string Name, CharacterGender Gender);

public record EquipItemRequest(CharacterSlot Slot, Guid ItemDefinitionId);

public record UnequipItemRequest(CharacterSlot Slot);

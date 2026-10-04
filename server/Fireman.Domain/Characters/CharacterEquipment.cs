using Fireman.Domain.Common;
using Fireman.Shared.Enums;

namespace Fireman.Domain.Characters;

public class CharacterEquipment : Entity<Guid>
{
    public Guid CharacterId { get; private set; }
    public CharacterSlot Slot { get; private set; }
    public Guid ItemDefinitionId { get; private set; }
    public DateTime EquippedAt { get; private set; }

    private CharacterEquipment() { }

    public CharacterEquipment(Guid characterId, CharacterSlot slot, Guid itemDefinitionId)
    {
        Id = Guid.NewGuid();
        CharacterId = characterId;
        Slot = slot;
        ItemDefinitionId = itemDefinitionId;
        EquippedAt = DateTime.UtcNow;
    }
}

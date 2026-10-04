using Fireman.Domain.Characters;
using Fireman.Domain.Inventory;
using Fireman.Domain.Policies;
using Fireman.Domain.Users;
using Fireman.Shared.Enums;

namespace Fireman.Application.Policies;

public record CanEquipItemContext(
    User User,
    Character Character,
    ItemDefinition Item,
    InventoryItem? InventoryOwnership,
    CharacterSlot Slot
);

public class CanEquipItemPolicy : IGamePolicy<CanEquipItemContext>
{
    public PolicyResult Evaluate(CanEquipItemContext context)
    {
        if (context.User.Status != UserStatus.Active)
            return PolicyResult.Deny("User account is not active.");

        if (context.InventoryOwnership is null || context.InventoryOwnership.Quantity <= 0)
            return PolicyResult.Deny("User does not own this item in inventory.");

        if (context.Item.CompatibleSlot is not null && context.Item.CompatibleSlot != context.Slot)
            return PolicyResult.Deny($"Item slot mismatch. Item is for {context.Item.CompatibleSlot}, but requested {context.Slot}.");

        return PolicyResult.Allow();
    }
}

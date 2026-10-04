using Fireman.Domain.Characters;
using Fireman.Domain.Economy;
using Fireman.Domain.Inventory;
using Fireman.Domain.Missions;
using Fireman.Domain.Policies;
using Fireman.Domain.Users;
using Fireman.Shared.Enums;

namespace Fireman.Application.Policies;

public record CanBuyItemContext(
    User User,
    Wallet Wallet,
    ItemDefinition Item,
    int Quantity,
    int FinalTotalPrice
);

public class CanBuyItemPolicy : IGamePolicy<CanBuyItemContext>
{
    public PolicyResult Evaluate(CanBuyItemContext context)
    {
        if (context.User.Status != UserStatus.Active)
            return PolicyResult.Deny("User account is not active.");

        if (!context.Item.IsPurchasable)
            return PolicyResult.Deny("Item is not available for purchase.");

        if (context.Item.CurrencyType == CurrencyType.Coins && context.Wallet.Coins < context.FinalTotalPrice)
            return PolicyResult.Deny($"Insufficient coins. Required: {context.FinalTotalPrice}, Available: {context.Wallet.Coins}");

        if (context.Item.CurrencyType == CurrencyType.Gems && context.Wallet.Gems < context.FinalTotalPrice)
            return PolicyResult.Deny($"Insufficient gems. Required: {context.FinalTotalPrice}, Available: {context.Wallet.Gems}");

        return PolicyResult.Allow();
    }
}

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

public record CanStartMissionContext(
    User User,
    Character Character,
    Mission Mission,
    UserMission? ActiveMission
);

public class CanStartMissionPolicy : IGamePolicy<CanStartMissionContext>
{
    public PolicyResult Evaluate(CanStartMissionContext context)
    {
        if (context.User.Status != UserStatus.Active)
            return PolicyResult.Deny("User account is not active.");

        if (context.Character.Level < context.Mission.RequiredLevel)
            return PolicyResult.Deny($"Level {context.Mission.RequiredLevel} required to start this mission. Current level: {context.Character.Level}");

        if (context.ActiveMission is not null && context.ActiveMission.Status == MissionStatus.InProgress)
            return PolicyResult.Deny("Another mission is already in progress.");

        return PolicyResult.Allow();
    }
}

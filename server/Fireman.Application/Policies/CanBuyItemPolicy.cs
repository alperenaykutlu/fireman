using Fireman.Domain.Economy;
using Fireman.Domain.Inventory;
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

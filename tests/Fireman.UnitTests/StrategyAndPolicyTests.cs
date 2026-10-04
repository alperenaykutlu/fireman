using Fireman.Application.Policies;
using Fireman.Application.Strategies.Pricing;
using Fireman.Application.Strategies.Rewards;
using Fireman.Domain.Characters;
using Fireman.Domain.Economy;
using Fireman.Domain.Inventory;
using Fireman.Domain.Missions;
using Fireman.Domain.Users;
using Fireman.Shared.Enums;
using Xunit;

namespace Fireman.UnitTests;

public class StrategyAndPolicyTests
{
    [Fact]
    public void RewardStrategyFactory_ShouldProvideCorrectStrategiesByRole()
    {
        var factory = new RewardStrategyFactory();

        var userStrategy = factory.GetStrategy(UserRole.User);
        var modStrategy = factory.GetStrategy(UserRole.Moderator);
        var adminStrategy = factory.GetStrategy(UserRole.Admin);

        var context = new RewardContext(Guid.NewGuid(), UserRole.User, 100, 100, 2);

        var normalResult = userStrategy.Calculate(context);
        var modResult = modStrategy.Calculate(context);
        var adminResult = adminStrategy.Calculate(context);

        Assert.Equal(1.0, normalResult.Multiplier);
        Assert.Equal(1.2, modResult.Multiplier);
        Assert.Equal(1.2, adminResult.Multiplier);
        Assert.True(modResult.TotalCoins > normalResult.TotalCoins);
    }

    [Fact]
    public void PricingStrategyFactory_ShouldApplyDiscountsForVIPs()
    {
        var factory = new PricingStrategyFactory();

        var userStrategy = factory.GetStrategy(UserRole.User);
        var adminStrategy = factory.GetStrategy(UserRole.Admin);

        var regularPrice = userStrategy.CalculatePrice(new PricingContext(UserRole.User, 1000));
        var vipPrice = adminStrategy.CalculatePrice(new PricingContext(UserRole.Admin, 1000));

        Assert.Equal(1000, regularPrice.FinalPrice);
        Assert.Equal(850, vipPrice.FinalPrice); // 15% discount
    }

    [Fact]
    public void CanBuyItemPolicy_WhenInsufficientBalance_ShouldDeny()
    {
        var policy = new CanBuyItemPolicy();
        var user = User.Create(Username.Create("player1"), "player@test.com", "hash");
        var wallet = Wallet.Create(user.Id, initialCoins: 100, initialGems: 0);

        var item = new ItemDefinition(
            Guid.NewGuid(), "Super Axe", "Desc", ItemType.Equipment,
            ItemRarity.Rare, CharacterSlot.Accessory, 500, CurrencyType.Coins, true, "asset_axe");

        var context = new CanBuyItemContext(user, wallet, item, 1, 500);
        var result = policy.Evaluate(context);

        Assert.False(result.IsAllowed);
        Assert.Contains("Insufficient coins", result.Reason);
    }

    [Fact]
    public void CanEquipItemPolicy_WhenUserDoesNotOwnItem_ShouldDeny()
    {
        var policy = new CanEquipItemPolicy();
        var user = User.Create(Username.Create("player1"), "player@test.com", "hash");
        var character = Character.Create(user.Id, "FiremanBob", CharacterGender.Male);

        var item = new ItemDefinition(
            Guid.NewGuid(), "Chief Hat", "Desc", ItemType.Cosmetic,
            ItemRarity.Rare, CharacterSlot.Hat, 250, CurrencyType.Coins, true, "asset_hat");

        // Inventory ownership is null
        var context = new CanEquipItemContext(user, character, item, null, CharacterSlot.Hat);
        var result = policy.Evaluate(context);

        Assert.False(result.IsAllowed);
        Assert.Contains("does not own", result.Reason);
    }
}

using Fireman.Domain.Characters;
using Fireman.Domain.Economy;
using Fireman.Domain.Users;
using Fireman.Shared.Enums;
using Fireman.Shared.Exceptions;
using Xunit;

namespace Fireman.UnitTests;

public class DomainEntityTests
{
    [Fact]
    public void Character_EquipItem_ShouldEquipAndReplaceExistingSlot()
    {
        var character = Character.Create(Guid.NewGuid(), "CaptainSpark", CharacterGender.Male);
        var hat1 = Guid.NewGuid();
        var hat2 = Guid.NewGuid();

        character.EquipItem(CharacterSlot.Hat, hat1);
        Assert.Single(character.EquippedItems);
        Assert.Equal(hat1, character.EquippedItems.First().ItemDefinitionId);

        character.EquipItem(CharacterSlot.Hat, hat2);
        Assert.Single(character.EquippedItems);
        Assert.Equal(hat2, character.EquippedItems.First().ItemDefinitionId);
    }

    [Fact]
    public void Character_AddExperience_ShouldLevelUpWhenThresholdCrossed()
    {
        var character = Character.Create(Guid.NewGuid(), "CaptainSpark", CharacterGender.Male);
        Assert.Equal(1, character.Level);

        bool leveledUp = character.AddExperience(1200, out int newLevel);

        Assert.True(leveledUp);
        Assert.Equal(2, newLevel);
        Assert.Equal(2, character.Level);
    }

    [Fact]
    public void Wallet_DeductCurrency_WhenInsufficient_ShouldThrowValidationException()
    {
        var wallet = Wallet.Create(Guid.NewGuid(), initialCoins: 100, initialGems: 5);

        Assert.Throws<ValidationException>(() => wallet.DeductCurrency(CurrencyType.Coins, 150));
        Assert.Throws<ValidationException>(() => wallet.DeductCurrency(CurrencyType.Gems, 10));
    }

    [Fact]
    public void Wallet_AddCurrency_ShouldIncreaseBalances()
    {
        var wallet = Wallet.Create(Guid.NewGuid(), initialCoins: 100, initialGems: 5);

        wallet.AddCurrency(CurrencyType.Coins, 50);
        wallet.AddCurrency(CurrencyType.Gems, 2);

        Assert.Equal(150, wallet.Coins);
        Assert.Equal(7, wallet.Gems);
    }
}

using Fireman.Domain.Users;
using Fireman.Shared.Exceptions;
using Xunit;

namespace Fireman.UnitTests;

public class UsernameTests
{
    [Theory]
    [InlineData("firefighter_99")]
    [InlineData("chief12")]
    [InlineData("Rescue-Hero")]
    public void Create_WithValidUsername_ShouldSucceed(string raw)
    {
        var username = Username.Create(raw);
        Assert.Equal(raw.Trim(), username.Value);
        Assert.Equal(raw.Trim().ToUpperInvariant(), username.NormalizedValue);
    }

    [Theory]
    [InlineData("ab")] // Too short (< 3)
    [InlineData("this_username_is_way_too_long_for_game_limits")] // > 20
    [InlineData("invalid user!")] // Contains spaces / special chars
    [InlineData("")]
    public void Create_WithInvalidFormat_ShouldThrowValidationException(string raw)
    {
        Assert.Throws<ValidationException>(() => Username.Create(raw));
    }

    [Theory]
    [InlineData("admin")]
    [InlineData("ADMIN")]
    [InlineData("administrator")]
    [InlineData("fireman")]
    [InlineData("FIREMAN")]
    [InlineData("system")]
    public void Create_WithReservedUsername_ShouldThrowValidationException(string reserved)
    {
        Assert.Throws<ValidationException>(() => Username.Create(reserved));
    }

    [Fact]
    public void Equals_TwoUsernamesWithDifferentCasing_ShouldBeEqual()
    {
        var u1 = Username.Create("RescueHero");
        var u2 = Username.Create("rescuehero");

        Assert.Equal(u1, u2);
    }
}

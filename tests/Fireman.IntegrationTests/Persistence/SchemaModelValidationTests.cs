using Fireman.Domain.Characters;
using Fireman.Domain.Economy;
using Fireman.Domain.Matches;
using Fireman.Domain.Social;
using Fireman.Domain.Users;
using Fireman.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace Fireman.IntegrationTests.Persistence;

public sealed class SchemaModelValidationTests
{
    [Fact]
    public void ModelBuilder_InitializesWithoutErrors_AndContainsAllAggregateRoots()
    {
        // Arrange
        var options = new DbContextOptionsBuilder<FiremanDbContext>()
            .UseInMemoryDatabase(databaseName: "SchemaValidationTestDb")
            .Options;

        // Act
        using var context = new FiremanDbContext(options);
        var model = context.Model;

        // Assert
        Assert.NotNull(model);

        var entityTypes = model.GetEntityTypes().Select(e => e.ClrType).ToHashSet();

        Assert.Contains(typeof(User), entityTypes);
        Assert.Contains(typeof(Character), entityTypes);
        Assert.Contains(typeof(Wallet), entityTypes);
        Assert.Contains(typeof(Match), entityTypes);
        Assert.Contains(typeof(MatchPlayer), entityTypes);
        Assert.Contains(typeof(Friendship), entityTypes);
        Assert.Contains(typeof(Clan), entityTypes);
        Assert.Contains(typeof(ClanMember), entityTypes);
    }

    [Fact]
    public void ClanModelConfiguration_HasCorrectCascadeAndForeignKeys()
    {
        // Arrange
        var options = new DbContextOptionsBuilder<FiremanDbContext>()
            .UseInMemoryDatabase(databaseName: "ClanSchemaTestDb")
            .Options;

        using var context = new FiremanDbContext(options);
        var clanEntity = context.Model.FindEntityType(typeof(Clan));
        var memberEntity = context.Model.FindEntityType(typeof(ClanMember));

        // Assert
        Assert.NotNull(clanEntity);
        Assert.NotNull(memberEntity);

        var foreignKey = memberEntity.GetForeignKeys()
            .FirstOrDefault(fk => fk.PrincipalEntityType == clanEntity);

        Assert.NotNull(foreignKey);
        Assert.Equal(DeleteBehavior.Cascade, foreignKey.DeleteBehavior);
    }
}

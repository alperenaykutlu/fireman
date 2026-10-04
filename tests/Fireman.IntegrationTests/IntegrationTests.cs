using Fireman.Application;
using Fireman.Application.Auth;
using Fireman.Application.Characters;
using Fireman.Application.Common.Interfaces;
using Fireman.Application.Inventory;
using Fireman.Application.Missions;
using Fireman.Application.OfflineSync;
using Fireman.Contracts.Auth;
using Fireman.Contracts.Characters;
using Fireman.Contracts.Inventory;
using Fireman.Contracts.Missions;
using Fireman.Contracts.Offline;
using Fireman.Domain.Users;
using Fireman.Infrastructure;
using Fireman.Infrastructure.Persistence;
using Fireman.Shared.Enums;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Fireman.IntegrationTests;

public class TestCurrentUser : ICurrentUser
{
    public Guid? UserId { get; set; }
    public string? Username { get; set; }
    public UserRole? Role { get; set; }
    public bool IsAuthenticated => UserId.HasValue;
}

public class IntegrationTests
{
    private readonly IServiceProvider _serviceProvider;
    private readonly TestCurrentUser _testCurrentUser;

    public IntegrationTests()
    {
        var services = new ServiceCollection();
        var configuration = new ConfigurationBuilder().Build();

        services.AddLogging();
        services.AddApplication();
        services.AddInfrastructure(configuration);

        _testCurrentUser = new TestCurrentUser();
        services.AddSingleton<ICurrentUser>(_testCurrentUser);

        _serviceProvider = services.BuildServiceProvider();
    }

    [Fact]
    public async Task CompleteGameplayFlow_ShouldExecuteSuccessfully()
    {
        var authService = _serviceProvider.GetRequiredService<IAuthService>();
        var characterService = _serviceProvider.GetRequiredService<ICharacterService>();
        var inventoryService = _serviceProvider.GetRequiredService<IInventoryService>();
        var missionService = _serviceProvider.GetRequiredService<IMissionService>();
        var offlineSyncService = _serviceProvider.GetRequiredService<IOfflineSyncService>();
        var dbContext = _serviceProvider.GetRequiredService<InMemoryDbContext>();

        // 1. Register User
        var registerResult = await authService.RegisterAsync(new RegisterRequest(
            "FireHero2026",
            "firehero@domain.com",
            "SecretPassword123!"));

        Assert.True(registerResult.IsSuccess);
        Assert.NotNull(registerResult.Value.AccessToken);

        // Impersonate as registered user
        _testCurrentUser.UserId = registerResult.Value.UserId;
        _testCurrentUser.Username = registerResult.Value.Username;
        _testCurrentUser.Role = registerResult.Value.Role;

        // 2. Verify Character and Initial Wallet
        var charResult = await characterService.GetCharacterAsync();
        Assert.True(charResult.IsSuccess);
        Assert.Equal("FireHero2026", charResult.Value.Name);
        Assert.Equal(1, charResult.Value.Level);

        var wallet = dbContext.Wallets.Values.First(w => w.UserId == _testCurrentUser.UserId.Value);
        Assert.Equal(1000, wallet.Coins); // Initial starter bonus

        // 3. Buy Fire Helmet from shop
        var helmetDef = dbContext.ItemDefinitions.Values.First(i => i.CompatibleSlot == CharacterSlot.Hat);
        var buyResult = await inventoryService.BuyItemAsync(new BuyItemRequest(helmetDef.Id, 1));
        Assert.True(buyResult.IsSuccess);
        Assert.Equal(helmetDef.Id, buyResult.Value.ItemDefinitionId);
        Assert.Equal(750, wallet.Coins); // 1000 - 250

        // 4. Server-Authoritative Item Equip
        var equipResult = await characterService.EquipItemAsync(new EquipItemRequest(CharacterSlot.Hat, helmetDef.Id));
        Assert.True(equipResult.IsSuccess);
        Assert.Single(equipResult.Value.EquippedItems);
        Assert.Equal(CharacterSlot.Hat, equipResult.Value.EquippedItems[0].Slot);

        // 5. Start and Complete Mission with Reward Strategy & Events
        var mission = dbContext.Missions.Values.First();
        var startResult = await missionService.StartMissionAsync(new StartMissionRequest(mission.Id));
        Assert.True(startResult.IsSuccess);

        var completeResult = await missionService.CompleteMissionAsync(new CompleteMissionRequest(
            mission.Id,
            FinalScore: 600,
            RescuesCompleted: 3,
            DurationSeconds: 45));

        Assert.True(completeResult.IsSuccess);
        Assert.True(completeResult.Value.EarnedCoins > 0);
        Assert.True(completeResult.Value.EarnedXp > 0);

        // 6. Test Offline Action Sync (Anti-Cheat check: Valid vs Invalid future timestamp)
        var offlineBatch = new OfflineSyncRequest(
            Guid.NewGuid(),
            new List<OfflineActionDto>
            {
                // Valid offline action
                new(Guid.NewGuid(), "AddCoins", "50", DateTime.UtcNow.AddMinutes(-5), "hash1"),
                // Suspicious future timestamp action
                new(Guid.NewGuid(), "AddCoins", "50", DateTime.UtcNow.AddHours(2), "hash2")
            });

        var syncResult = await offlineSyncService.SynchronizeOfflineActionsAsync(offlineBatch);
        Assert.True(syncResult.IsSuccess);
        Assert.Equal(1, syncResult.Value.AcceptedCount);
        Assert.Equal(1, syncResult.Value.RejectedCount);
    }
}

using Fireman.Application.Auth;
using Fireman.Application.Characters;
using Fireman.Application.Events;
using Fireman.Application.Events.Handlers;
using Fireman.Application.Inventory;
using Fireman.Application.Leaderboard;
using Fireman.Application.Matches;
using Fireman.Application.Missions;
using Fireman.Application.OfflineSync;
using Fireman.Application.Policies;
using Fireman.Application.Strategies.Pricing;
using Fireman.Application.Strategies.Rewards;
using Fireman.Application.Users;
using Fireman.Domain.Policies;
using Microsoft.Extensions.DependencyInjection;

namespace Fireman.Application;

public static class DependencyInjection
{
    public static IServiceCollection AddApplication(this IServiceCollection services)
    {
        // Use Cases / Services
        services.AddScoped<IAuthService, AuthService>();
        services.AddScoped<IUserService, UserService>();
        services.AddScoped<ICharacterService, CharacterService>();
        services.AddScoped<IInventoryService, InventoryService>();
        services.AddScoped<IMissionService, MissionService>();
        services.AddScoped<IMatchService, MatchService>();
        services.AddScoped<ILeaderboardService, LeaderboardService>();
        services.AddScoped<IOfflineSyncService, OfflineSyncService>();
        services.AddScoped<Admin.IAdminService, Admin.AdminService>();
        services.AddScoped<Social.ISocialService, Social.SocialService>();
        services.AddScoped<Economy.IWalletService, Economy.WalletService>();
        services.AddScoped<Seasons.ISeasonService, Seasons.SeasonService>();
        services.AddScoped<Notifications.INotificationService, Notifications.NotificationService>();
        services.AddScoped<AntiCheat.IAntiCheatValidationService, AntiCheat.AntiCheatValidationService>();

        // Save System Migration
        services.AddSingleton<Fireman.Domain.SaveSystem.ISaveMigrationService, Fireman.Domain.SaveSystem.SaveMigrationService>();

        // Strategies & Factories
        services.AddSingleton<IRewardStrategyFactory, RewardStrategyFactory>();
        services.AddSingleton<IPricingStrategyFactory, PricingStrategyFactory>();

        // Policies
        services.AddScoped<CanJoinMatchPolicy>();
        services.AddScoped<IGamePolicy<CanJoinMatchContext>, CanJoinMatchPolicy>();
        services.AddScoped<IGamePolicy<CanBuyItemContext>, CanBuyItemPolicy>();
        services.AddScoped<IGamePolicy<CanEquipItemContext>, CanEquipItemPolicy>();
        services.AddScoped<IGamePolicy<CanStartMissionContext>, CanStartMissionPolicy>();

        // Event Handlers
        services.AddScoped<IEventHandler<MissionCompletedEvent>, RewardEventHandler>();
        services.AddScoped<IEventHandler<MissionCompletedEvent>, AchievementEventHandler>();
        services.AddScoped<IEventHandler<MissionCompletedEvent>, AnalyticsEventHandler>();
        services.AddScoped<IEventHandler<MissionCompletedEvent>, NotificationEventHandler>();
        services.AddScoped<IEventHandler<ItemPurchasedEvent>, AnalyticsEventHandler>();
        services.AddScoped<IEventHandler<ItemEquippedEvent>, CharacterCacheInvalidationHandler>();
        services.AddScoped<IEventHandler<MissionCompletedEvent>, LeaderboardCacheInvalidationHandler>();
        services.AddScoped<IEventHandler<MatchFinishedEvent>, LeaderboardCacheInvalidationHandler>();

        return services;
    }
}

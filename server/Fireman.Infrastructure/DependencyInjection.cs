using Fireman.Application.Common.Interfaces;
using Fireman.Application.Events;
using Fireman.Domain.AntiCheat;
using Fireman.Domain.Characters;
using Fireman.Domain.Economy;
using Fireman.Domain.Inventory;
using Fireman.Domain.Matches;
using Fireman.Domain.Missions;
using Fireman.Domain.Users;
using Fireman.Infrastructure.Caching;
using Fireman.Infrastructure.Messaging;
using Fireman.Infrastructure.Persistence;
using Fireman.Infrastructure.Persistence.Repositories;
using Fireman.Infrastructure.Security;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace Fireman.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        // Persistence
        services.AddSingleton<InMemoryDbContext>();
        services.AddScoped<IUnitOfWork, UnitOfWork>();

        // Repositories
        services.AddScoped<IUserRepository, UserRepository>();
        services.AddScoped<ICharacterRepository, CharacterRepository>();
        services.AddScoped<IInventoryRepository, InventoryRepository>();
        services.AddScoped<IItemDefinitionRepository, ItemDefinitionRepository>();
        services.AddScoped<IMissionRepository, MissionRepository>();
        services.AddScoped<IUserMissionRepository, UserMissionRepository>();
        services.AddScoped<IMatchRepository, MatchRepository>();
        services.AddScoped<IWalletRepository, WalletRepository>();
        services.AddScoped<ICurrencyLedgerRepository, CurrencyLedgerRepository>();
        services.AddScoped<IAntiCheatRepository, AntiCheatRepository>();
        services.AddScoped<IOutboxRepository, OutboxRepository>();
        services.AddScoped<Fireman.Domain.Audit.IAuditLogRepository, Fireman.Infrastructure.Persistence.Repositories.AuditLogRepository>();
        services.AddScoped<Fireman.Domain.Social.IFriendshipRepository, Fireman.Infrastructure.Persistence.Repositories.FriendshipRepository>();
        services.AddScoped<Fireman.Domain.Social.IPlayerReportRepository, Fireman.Infrastructure.Persistence.Repositories.PlayerReportRepository>();

        // Feature Flags
        services.AddSingleton<IFeatureFlagService, Fireman.Infrastructure.Services.FeatureFlagService>();

        // Idempotency
        services.AddSingleton<IIdempotencyService, Fireman.Infrastructure.Persistence.IdempotencyService>();

        // Hosted Services
        services.AddHostedService<Fireman.Infrastructure.BackgroundServices.OutboxProcessorBackgroundService>();

        // Security & Tokens
        services.AddSingleton<IPasswordHasher, PasswordHasher>();
        services.AddSingleton<ITokenService, JwtTokenService>();

        // Cache
        services.AddMemoryCache();
        services.AddSingleton<ICacheService, MemoryCacheService>();

        // Messaging
        services.AddSingleton<IEventBus, InMemoryEventBus>();

        return services;
    }
}

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
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Google.Cloud.Firestore;

namespace Fireman.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        // Persistence
        var persistenceProvider = configuration["Persistence:Provider"] ?? "InMemory";
        if (string.Equals(persistenceProvider, "Firestore", StringComparison.OrdinalIgnoreCase))
        {
            var projectId = configuration["Firebase:ProjectId"];
            if (string.IsNullOrWhiteSpace(projectId))
                throw new InvalidOperationException("Firebase:ProjectId is required when Persistence:Provider is Firestore.");

            services.AddSingleton(_ => FirestoreDb.Create(projectId));
            services.AddSingleton<DatabaseCircuitBreaker>();
            services.AddSingleton<IDocumentDatabase, FirestoreDocumentDatabase>();
        }
        else if (string.Equals(persistenceProvider, "InMemory", StringComparison.OrdinalIgnoreCase))
        {
            services.AddSingleton<InMemoryDbContext>();
            services.AddSingleton<IDocumentDatabase, InMemoryDocumentDatabase>();
        }
        else if (string.Equals(persistenceProvider, "Postgres", StringComparison.OrdinalIgnoreCase))
        {
            var connectionString = configuration.GetConnectionString("DefaultConnection");
            if (string.IsNullOrWhiteSpace(connectionString))
                throw new InvalidOperationException("ConnectionStrings:DefaultConnection is required when Persistence:Provider is Postgres.");
            services.AddDbContext<FiremanDbContext>(options => options.UseNpgsql(connectionString));
            services.AddSingleton<DatabaseCircuitBreaker>();
            services.AddScoped<IDocumentDatabase, PostgresDocumentDatabase>();
        }
        else
        {
            throw new InvalidOperationException($"Unsupported Persistence:Provider '{persistenceProvider}'. Use Firestore, Postgres, or InMemory.");
        }
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
        services.AddScoped<Fireman.Domain.Social.IDirectMessageRepository, Fireman.Infrastructure.Persistence.Repositories.DirectMessageRepository>();
        services.AddScoped<Fireman.Domain.Social.IPlayerReportRepository, Fireman.Infrastructure.Persistence.Repositories.PlayerReportRepository>();
        services.AddScoped<Fireman.Domain.Seasons.ISeasonRepository, Fireman.Infrastructure.Persistence.Repositories.SeasonRepository>();
        services.AddScoped<Fireman.Domain.Notifications.INotificationRepository, Fireman.Infrastructure.Persistence.Repositories.NotificationRepository>();

        // Feature Flags, Remote Config & IAP Validation
        services.AddSingleton<IFeatureFlagService, Fireman.Infrastructure.Services.FeatureFlagService>();
        services.AddSingleton<IRemoteConfigService, Fireman.Infrastructure.Services.RemoteConfigService>();
        services.AddSingleton<Fireman.Infrastructure.Services.IIapReceiptValidationService, Fireman.Infrastructure.Services.IapReceiptValidationService>();

        // Idempotency
        services.AddSingleton<IIdempotencyService, Fireman.Infrastructure.Persistence.IdempotencyService>();

        // Hosted Services
        services.AddHostedService<Fireman.Infrastructure.BackgroundServices.OutboxProcessorBackgroundService>();
        services.AddHostedService<GameCatalogSeeder>();

        // Security & Tokens
        services.AddSingleton<IPasswordHasher, PasswordHasher>();
        services.AddSingleton<ITokenService, JwtTokenService>();
        services.AddSingleton<IGoogleIdentityVerifier, GoogleIdentityVerifier>();

        // Cache
        services.AddMemoryCache();
        services.AddSingleton<ICacheService, MemoryCacheService>();

        // Messaging
        services.AddSingleton<IEventBus, InMemoryEventBus>();

        return services;
    }
}

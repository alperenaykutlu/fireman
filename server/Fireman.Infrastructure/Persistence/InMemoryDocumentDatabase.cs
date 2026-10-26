using System.Collections.Concurrent;
using Fireman.Application.Common.Interfaces;
using Fireman.Domain.AntiCheat;
using Fireman.Domain.Audit;
using Fireman.Domain.Characters;
using Fireman.Domain.Economy;
using Fireman.Domain.Inventory;
using Fireman.Domain.Matches;
using Fireman.Domain.Missions;
using Fireman.Domain.Notifications;
using Fireman.Domain.Seasons;
using Fireman.Domain.Social;
using Fireman.Domain.Users;

namespace Fireman.Infrastructure.Persistence;

/// <summary>Local development/test adapter for the same provider-neutral document boundary.</summary>
public sealed class InMemoryDocumentDatabase : IDocumentDatabase
{
    private readonly ConcurrentDictionary<string, ConcurrentDictionary<string, object>> _collections = new(StringComparer.Ordinal);

    public InMemoryDocumentDatabase(InMemoryDbContext seed)
    {
        Seed("users", seed.Users.Values);
        Seed("characters", seed.Characters.Values);
        Seed("inventoryItems", seed.InventoryItems.Values);
        Seed("itemDefinitions", seed.ItemDefinitions.Values);
        Seed("missions", seed.Missions.Values);
        Seed("userMissions", seed.UserMissions.Values);
        Seed("matches", seed.Matches.Values);
        Seed("directMessages", seed.DirectMessages.Values);
        Seed("friendships", seed.Friendships.Values);
        Seed("wallets", seed.Wallets.Values);
        Seed("currencyLedger", seed.CurrencyLedger);
        Seed("antiCheatLogs", seed.AntiCheatLogs);
        Seed("outboxMessages", seed.OutboxMessages);
        Seed("playerReports", Array.Empty<PlayerReport>());
        Seed("auditLogs", Array.Empty<AuditLog>());
        Seed("seasons", Array.Empty<Season>());
        Seed("seasonProgress", Array.Empty<UserSeasonProgress>());
        Seed("notifications", Array.Empty<InAppNotification>());
    }

    public Task<T?> GetAsync<T>(string collection, string id, CancellationToken cancellationToken = default) where T : class
    {
        cancellationToken.ThrowIfCancellationRequested();
        return Task.FromResult(GetCollection(collection).TryGetValue(id, out var value) ? value as T : null);
    }

    public Task<IReadOnlyList<T>> GetAllAsync<T>(string collection, CancellationToken cancellationToken = default) where T : class
    {
        cancellationToken.ThrowIfCancellationRequested();
        IReadOnlyList<T> values = GetCollection(collection).Values.OfType<T>().Take(1000).ToList();
        return Task.FromResult(values);
    }

    public async Task<IReadOnlyList<T>> FindAsync<T>(string collection, IReadOnlyDictionary<string, string> filters, CancellationToken cancellationToken = default) where T : class
    {
        var all = await GetAllAsync<T>(collection, cancellationToken);
        return all.Where(item => filters.All(filter =>
        {
            var property = typeof(T).GetProperty(filter.Key, System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.IgnoreCase);
            var actual = property?.GetValue(item)?.ToString();
            if (actual is null && filter.Key.Equals("processedOn", StringComparison.OrdinalIgnoreCase)) actual = string.Empty;
            return actual?.Equals(filter.Value, StringComparison.OrdinalIgnoreCase) == true;
        })).ToList();
    }

    public Task SetAsync<T>(string collection, string id, T value, CancellationToken cancellationToken = default) where T : class
    {
        cancellationToken.ThrowIfCancellationRequested();
        GetCollection(collection)[id] = value;
        return Task.CompletedTask;
    }

    public Task<bool> TryCreateAsync<T>(string collection, string id, T value, CancellationToken cancellationToken = default) where T : class
    {
        cancellationToken.ThrowIfCancellationRequested();
        return Task.FromResult(GetCollection(collection).TryAdd(id, value));
    }

    public Task DeleteAsync(string collection, string id, CancellationToken cancellationToken = default)
    {
        cancellationToken.ThrowIfCancellationRequested();
        GetCollection(collection).TryRemove(id, out _);
        return Task.CompletedTask;
    }

    private ConcurrentDictionary<string, object> GetCollection(string collection) =>
        _collections.GetOrAdd(collection, _ => new ConcurrentDictionary<string, object>(StringComparer.Ordinal));

    private void Seed<T>(string collection, IEnumerable<T> values) where T : class
    {
        var documents = GetCollection(collection);
        foreach (var value in values)
        {
            var id = value.GetType().GetProperty("Id")?.GetValue(value)?.ToString();
            if (!string.IsNullOrWhiteSpace(id)) documents[id] = value;
        }
    }
}

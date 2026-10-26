using System.Collections;
using System.Reflection;
using System.Text.Json;
using Fireman.Application.Common.Interfaces;
using Fireman.Domain.Users;
using Google.Cloud.Firestore;

namespace Fireman.Infrastructure.Persistence;

public sealed class CircuitBreakerOpenException : Exception
{
    public CircuitBreakerOpenException(string message) : base(message) { }
}

public sealed class StorageUnavailableException(string message, Exception innerException) : Exception(message, innerException);

/// <summary>Small shared breaker for Firestore calls. The open interval prevents retry storms.</summary>
public sealed class DatabaseCircuitBreaker
{
    private readonly object _gate = new();
    private int _consecutiveFailures;
    private DateTime _openedUntilUtc;

    public async Task<T> ExecuteAsync<T>(Func<Task<T>> operation)
    {
        lock (_gate)
        {
            if (_openedUntilUtc > DateTime.UtcNow)
                throw new CircuitBreakerOpenException("Database is temporarily unavailable; retry shortly.");
            if (_openedUntilUtc != default)
            {
                _openedUntilUtc = default;
                _consecutiveFailures = 0;
            }
        }

        try
        {
            var result = await operation();
            lock (_gate) _consecutiveFailures = 0;
            return result;
        }
        catch (Exception ex) when (ex is not CircuitBreakerOpenException and not OperationCanceledException)
        {
            lock (_gate)
            {
                _consecutiveFailures++;
                if (_consecutiveFailures >= 5)
                    _openedUntilUtc = DateTime.UtcNow.AddSeconds(15);
            }
            throw new StorageUnavailableException("The configured storage provider failed.", ex);
        }
    }

    public async Task ExecuteAsync(Func<Task> operation) => await ExecuteAsync(async () =>
    {
        await operation();
        return true;
    });
}

/// <summary>Firestore adapter. Domain models are stored as JSON payloads to keep the provider boundary independent.</summary>
public sealed class FirestoreDocumentDatabase(FirestoreDb db, DatabaseCircuitBreaker breaker) : IDocumentDatabase
{
    internal static readonly JsonSerializerOptions JsonOptions = new() { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };
    private static readonly HashSet<string> IndexedFields = new(StringComparer.OrdinalIgnoreCase)
    {
        "id", "username", "normalizedUsername", "email", "userId", "friendUserId", "senderUserId",
        "recipientUserId", "itemDefinitionId", "missionId", "seasonId", "reportedUserId", "status", "processedOn"
    };

    public Task<T?> GetAsync<T>(string collection, string id, CancellationToken cancellationToken = default) where T : class =>
        breaker.ExecuteAsync(async () =>
        {
            var snapshot = await db.Collection(collection).Document(id).GetSnapshotAsync(cancellationToken);
            return snapshot.Exists ? DeserializePayload<T>(snapshot.GetValue<string>("payload")) : null;
        });

    public Task<IReadOnlyList<T>> GetAllAsync<T>(string collection, CancellationToken cancellationToken = default) where T : class =>
        breaker.ExecuteAsync(async () =>
        {
            var snapshot = await db.Collection(collection).Limit(1000).GetSnapshotAsync(cancellationToken);
            return (IReadOnlyList<T>)snapshot.Documents
                .Where(document => document.ContainsField("payload"))
                .Take(1000)
                .Select(document => DeserializePayload<T>(document.GetValue<string>("payload")))
                .Where(item => item is not null).Cast<T>().ToList();
        });

    public Task<IReadOnlyList<T>> FindAsync<T>(string collection, IReadOnlyDictionary<string, string> filters, CancellationToken cancellationToken = default) where T : class =>
        breaker.ExecuteAsync(async () =>
        {
            Query query = db.Collection(collection);
            foreach (var (field, value) in filters)
            {
                if (!IndexedFields.Contains(field)) throw new ArgumentException($"Unsupported Firestore query field '{field}'.", nameof(filters));
                query = query.WhereEqualTo($"fields.{field}", value);
            }
            var snapshot = await query.GetSnapshotAsync(cancellationToken);
            return (IReadOnlyList<T>)snapshot.Documents
                .Where(document => document.ContainsField("payload"))
                .Select(document => DeserializePayload<T>(document.GetValue<string>("payload")))
                .Where(item => item is not null).Cast<T>().ToList();
        });

    public Task SetAsync<T>(string collection, string id, T value, CancellationToken cancellationToken = default) where T : class =>
        breaker.ExecuteAsync(async () =>
        {
            await db.Collection(collection).Document(id).SetAsync(
                CreateDocument(value),
                cancellationToken: cancellationToken);
        });

    public Task<bool> TryCreateAsync<T>(string collection, string id, T value, CancellationToken cancellationToken = default) where T : class =>
        breaker.ExecuteAsync(async () =>
        {
            try
            {
                await db.Collection(collection).Document(id).CreateAsync(
                    CreateDocument(value),
                    cancellationToken);
                return true;
            }
            catch (Grpc.Core.RpcException ex) when (ex.StatusCode == Grpc.Core.StatusCode.AlreadyExists)
            {
                return false;
            }
        });

    public Task DeleteAsync(string collection, string id, CancellationToken cancellationToken = default) =>
        breaker.ExecuteAsync(async () => await db.Collection(collection).Document(id).DeleteAsync(cancellationToken: cancellationToken));

    internal static string SerializePayload<T>(T value) => JsonSerializer.Serialize(value, JsonOptions);
    internal static string SerializeIndexedFields<T>(T value)
    {
        using var document = JsonDocument.Parse(SerializePayload(value));
        var fields = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        foreach (var property in document.RootElement.EnumerateObject())
        {
            if (!IndexedFields.Contains(property.Name)) continue;
            var fieldValue = property.Value.ValueKind switch
            {
                JsonValueKind.String => property.Value.GetString(),
                JsonValueKind.Number => property.Value.GetRawText(),
                JsonValueKind.True => "true",
                JsonValueKind.False => "false",
                JsonValueKind.Null when property.Name.Equals("processedOn", StringComparison.OrdinalIgnoreCase) => string.Empty,
                _ => null
            };
            if (fieldValue is not null) fields[property.Name] = fieldValue;
        }
        return JsonSerializer.Serialize(fields, JsonOptions);
    }
    internal static T? DeserializePayload<T>(string json) where T : class => (T?)Hydrate(typeof(T), JsonDocument.Parse(json).RootElement);

    private static Dictionary<string, object> CreateDocument<T>(T value)
    {
        var payload = SerializePayload(value);
        var fields = JsonSerializer.Deserialize<Dictionary<string, string>>(SerializeIndexedFields(value), JsonOptions) ?? [];
        return new Dictionary<string, object> { ["payload"] = payload, ["fields"] = fields };
    }

    // Supports private aggregate setters/constructors without coupling domain types to Firestore attributes.
    private static object? Hydrate(Type type, JsonElement value)
    {
        var nullableType = Nullable.GetUnderlyingType(type);
        if (nullableType is not null) type = nullableType;
        if (value.ValueKind == JsonValueKind.Null) return null;
        if (type == typeof(Username)) return Username.Create(value.GetProperty("value").GetString()!);
        if (type.IsEnum || type.IsPrimitive || type == typeof(string) || type == typeof(decimal) || type == typeof(Guid) || type == typeof(DateTime) || type == typeof(DateTimeOffset))
            return JsonSerializer.Deserialize(value.GetRawText(), type, JsonOptions);
        if (type.IsGenericType && typeof(IEnumerable).IsAssignableFrom(type) && type != typeof(string))
        {
            var elementType = type.GetGenericArguments()[0];
            var listType = typeof(List<>).MakeGenericType(elementType);
            var list = (IList)Activator.CreateInstance(listType)!;
            foreach (var item in value.EnumerateArray()) list.Add(Hydrate(elementType, item));
            return list;
        }

        object instance;
        try { instance = Activator.CreateInstance(type, nonPublic: true) ?? System.Runtime.CompilerServices.RuntimeHelpers.GetUninitializedObject(type); }
        catch (MissingMethodException) { instance = System.Runtime.CompilerServices.RuntimeHelpers.GetUninitializedObject(type); }
        foreach (var jsonProperty in value.EnumerateObject())
        {
            var property = type.GetProperty(jsonProperty.Name, BindingFlags.Instance | BindingFlags.Public | BindingFlags.IgnoreCase);
            if (property is null || property.Name is "DomainEvents" or "NormalizedUsername" or "HasPassword") continue;
            var hydrated = Hydrate(property.PropertyType, jsonProperty.Value);
            var setter = property.GetSetMethod(nonPublic: true);
            if (setter is not null)
            {
                setter.Invoke(instance, [hydrated]);
                continue;
            }

            if (hydrated is not IEnumerable items || property.PropertyType == typeof(string)) continue;
            var elementType = property.PropertyType.IsGenericType ? property.PropertyType.GetGenericArguments()[0] : null;
            if (elementType is null) continue;
            var backingCollection = FindCollectionField(type, elementType)?.GetValue(instance);
            if (backingCollection is IList backingList)
            {
                foreach (var item in items) backingList.Add(item);
            }
            else
            {
                var add = backingCollection?.GetType().GetMethod("Add", [elementType]);
                if (add is not null)
                    foreach (var item in items) add.Invoke(backingCollection, [item]);
            }
        }
        return instance;
    }

    private static FieldInfo? FindCollectionField(Type type, Type elementType)
    {
        for (var current = type; current is not null; current = current.BaseType)
        {
            var listType = typeof(List<>).MakeGenericType(elementType);
            var hashSetType = typeof(HashSet<>).MakeGenericType(elementType);
            var field = current.GetFields(BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.DeclaredOnly)
                .FirstOrDefault(candidate => candidate.FieldType == listType || candidate.FieldType == hashSetType);
            if (field is not null) return field;
        }
        return null;
    }
}

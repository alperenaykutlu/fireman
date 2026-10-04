using System.Collections.Concurrent;
using System.Text.Json;

namespace Fireman.Mobile.LocalStorage;

public interface ILocalDataStore
{
    Task SetAsync<T>(string key, T value);
    Task<T?> GetAsync<T>(string key);
    Task RemoveAsync(string key);
    Task ClearAsync();
}

public class LocalDataStore : ILocalDataStore
{
    private readonly ConcurrentDictionary<string, string> _storage = new();

    public Task SetAsync<T>(string key, T value)
    {
        var json = JsonSerializer.Serialize(value);
        _storage[key] = json;
        return Task.CompletedTask;
    }

    public Task<T?> GetAsync<T>(string key)
    {
        if (_storage.TryGetValue(key, out var json))
        {
            return Task.FromResult(JsonSerializer.Deserialize<T>(json));
        }
        return Task.FromResult<T?>(default);
    }

    public Task RemoveAsync(string key)
    {
        _storage.TryRemove(key, out _);
        return Task.CompletedTask;
    }

    public Task ClearAsync()
    {
        _storage.Clear();
        return Task.CompletedTask;
    }
}

using System.Collections.Concurrent;
using Fireman.Application.Common.Interfaces;

namespace Fireman.Infrastructure.Persistence;

public class IdempotencyService : IIdempotencyService
{
    private readonly ConcurrentDictionary<string, (string? Result, DateTime Expiry)> _keys = new();

    public Task<bool> HasBeenProcessedAsync(string idempotencyKey, CancellationToken cancellationToken = default)
    {
        if (_keys.TryGetValue(idempotencyKey, out var entry))
        {
            if (DateTime.UtcNow <= entry.Expiry)
                return Task.FromResult(true);

            _keys.TryRemove(idempotencyKey, out _);
        }

        return Task.FromResult(false);
    }

    public Task MarkAsProcessedAsync(string idempotencyKey, string? resultJson = null, TimeSpan? expiry = null, CancellationToken cancellationToken = default)
    {
        var expiration = DateTime.UtcNow.Add(expiry ?? TimeSpan.FromHours(24));
        _keys[idempotencyKey] = (resultJson, expiration);
        return Task.CompletedTask;
    }

    public Task<string?> GetPreviousResultAsync(string idempotencyKey, CancellationToken cancellationToken = default)
    {
        if (_keys.TryGetValue(idempotencyKey, out var entry) && DateTime.UtcNow <= entry.Expiry)
        {
            return Task.FromResult(entry.Result);
        }

        return Task.FromResult<string?>(null);
    }
}

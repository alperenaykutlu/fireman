using Fireman.Application.Common.Interfaces;

namespace Fireman.Infrastructure.Persistence;

public sealed record IdempotencyEntry
{
    public DateTime ExpiresAtUtc { get; init; }
    public bool IsCompleted { get; init; }
    public int StatusCode { get; init; }
    public string? ContentType { get; init; }
    public string Body { get; init; } = string.Empty;
}

public sealed class IdempotencyService(IDocumentDatabase database) : IIdempotencyService
{
    private const string Collection = "idempotency";
    private static readonly TimeSpan Retention = TimeSpan.FromHours(24);

    public async Task<IdempotencyClaimResult> TryBeginAsync(string scopedKey, CancellationToken cancellationToken = default)
    {
        for (var attempt = 0; attempt < 3; attempt++)
        {
            var existing = await database.GetAsync<IdempotencyEntry>(Collection, scopedKey, cancellationToken);
            if (existing is not null)
            {
                if (existing.ExpiresAtUtc <= DateTime.UtcNow)
                {
                    await database.DeleteAsync(Collection, scopedKey, cancellationToken);
                    continue;
                }
                return existing.IsCompleted
                    ? new(false, false, existing.StatusCode, existing.ContentType, existing.Body)
                    : new(false, true);
            }

            var pending = new IdempotencyEntry { ExpiresAtUtc = DateTime.UtcNow.Add(Retention) };
            if (await database.TryCreateAsync(Collection, scopedKey, pending, cancellationToken)) return new(true, false);
        }
        return new(false, true);
    }

    public Task CompleteAsync(string scopedKey, int statusCode, string? contentType, string body, CancellationToken cancellationToken = default) =>
        database.SetAsync(Collection, scopedKey, new IdempotencyEntry
        {
            ExpiresAtUtc = DateTime.UtcNow.Add(Retention),
            IsCompleted = true,
            StatusCode = statusCode,
            ContentType = contentType,
            Body = body
        }, cancellationToken);

    public Task ReleaseAsync(string scopedKey, CancellationToken cancellationToken = default) => database.DeleteAsync(Collection, scopedKey, cancellationToken);
}

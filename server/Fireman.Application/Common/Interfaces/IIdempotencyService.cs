namespace Fireman.Application.Common.Interfaces;

public interface IIdempotencyService
{
    Task<bool> HasBeenProcessedAsync(string idempotencyKey, CancellationToken cancellationToken = default);
    Task MarkAsProcessedAsync(string idempotencyKey, string? resultJson = null, TimeSpan? expiry = null, CancellationToken cancellationToken = default);
    Task<string?> GetPreviousResultAsync(string idempotencyKey, CancellationToken cancellationToken = default);
}

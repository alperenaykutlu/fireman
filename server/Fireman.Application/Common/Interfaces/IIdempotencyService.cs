namespace Fireman.Application.Common.Interfaces;

public interface IIdempotencyService
{
    Task<IdempotencyClaimResult> TryBeginAsync(string scopedKey, CancellationToken cancellationToken = default);
    Task CompleteAsync(string scopedKey, int statusCode, string? contentType, string body, CancellationToken cancellationToken = default);
    Task ReleaseAsync(string scopedKey, CancellationToken cancellationToken = default);
}

public sealed record IdempotencyClaimResult(bool Acquired, bool InProgress, int? StatusCode = null, string? ContentType = null, string? Body = null);

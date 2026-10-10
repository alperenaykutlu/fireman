namespace Fireman.Application.Common.Interfaces;

public interface IRemoteConfigService
{
    Task<string> GetConfigJsonAsync(string configKey, string? clientVersion = null, CancellationToken cancellationToken = default);
    Task<T?> GetConfigAsync<T>(string configKey, string? clientVersion = null, CancellationToken cancellationToken = default);
}

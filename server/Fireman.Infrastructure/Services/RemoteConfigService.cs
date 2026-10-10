using System.Text.Json;
using Fireman.Application.Common.Interfaces;
using Microsoft.Extensions.Hosting;

namespace Fireman.Infrastructure.Services;

public class RemoteConfigService : IRemoteConfigService
{
    private readonly IHostEnvironment _environment;
    private readonly Dictionary<string, string> _cachedConfigs = new(StringComparer.OrdinalIgnoreCase);

    public RemoteConfigService(IHostEnvironment environment)
    {
        _environment = environment;
        LoadInitialConfigs();
    }

    private void LoadInitialConfigs()
    {
        var configDir = Path.Combine(_environment.ContentRootPath, "Config");
        if (Directory.Exists(configDir))
        {
            foreach (var file in Directory.GetFiles(configDir, "*.json"))
            {
                var key = Path.GetFileNameWithoutExtension(file);
                _cachedConfigs[key] = File.ReadAllText(file);
            }
        }
    }

    public Task<string> GetConfigJsonAsync(string configKey, string? clientVersion = null, CancellationToken cancellationToken = default)
    {
        if (_cachedConfigs.TryGetValue(configKey, out var json))
        {
            return Task.FromResult(json);
        }

        return Task.FromResult("{}");
    }

    public Task<T?> GetConfigAsync<T>(string configKey, string? clientVersion = null, CancellationToken cancellationToken = default)
    {
        if (_cachedConfigs.TryGetValue(configKey, out var json))
        {
            var parsed = JsonSerializer.Deserialize<T>(json, new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            });
            return Task.FromResult(parsed);
        }

        return Task.FromResult<T?>(default);
    }
}

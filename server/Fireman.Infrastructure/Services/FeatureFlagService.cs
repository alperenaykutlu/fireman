using System.Collections.Concurrent;
using Fireman.Application.Common.Interfaces;
using Fireman.Contracts.Features;

namespace Fireman.Infrastructure.Services;

public class FeatureFlagService : IFeatureFlagService
{
    private readonly ConcurrentDictionary<string, bool> _flags = new(StringComparer.OrdinalIgnoreCase);

    public FeatureFlagService()
    {
        // Default flags
        _flags[FeatureNames.EnableMultiplayer] = true;
        _flags[FeatureNames.EnableTrading] = false; // Under development
        _flags[FeatureNames.EnableSeasonPass] = true;
        _flags[FeatureNames.EnableAntiCheatStrict] = true;
        _flags[FeatureNames.EnableVoiceChat] = false;
        _flags[FeatureNames.EnableMaintenanceMode] = false;
    }

    public Task<bool> IsEnabledAsync(string featureName, Guid? userId = null, CancellationToken cancellationToken = default)
    {
        var enabled = _flags.GetValueOrDefault(featureName, false);
        return Task.FromResult(enabled);
    }

    public Task<IReadOnlyDictionary<string, bool>> GetAllFlagsAsync(CancellationToken cancellationToken = default)
    {
        return Task.FromResult<IReadOnlyDictionary<string, bool>>(_flags);
    }

    public Task SetFlagAsync(string featureName, bool isEnabled, CancellationToken cancellationToken = default)
    {
        _flags[featureName] = isEnabled;
        return Task.CompletedTask;
    }
}

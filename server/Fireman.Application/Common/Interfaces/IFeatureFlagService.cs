namespace Fireman.Application.Common.Interfaces;

public interface IFeatureFlagService
{
    Task<bool> IsEnabledAsync(string featureName, Guid? userId = null, CancellationToken cancellationToken = default);
    Task<IReadOnlyDictionary<string, bool>> GetAllFlagsAsync(CancellationToken cancellationToken = default);
    Task SetFlagAsync(string featureName, bool isEnabled, CancellationToken cancellationToken = default);
}

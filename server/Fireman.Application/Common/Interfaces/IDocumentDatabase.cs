namespace Fireman.Application.Common.Interfaces;

/// <summary>Provider-neutral persistence boundary for application data.</summary>
public interface IDocumentDatabase
{
    Task<T?> GetAsync<T>(string collection, string id, CancellationToken cancellationToken = default) where T : class;
    Task<IReadOnlyList<T>> GetAllAsync<T>(string collection, CancellationToken cancellationToken = default) where T : class;
    Task<IReadOnlyList<T>> FindAsync<T>(string collection, IReadOnlyDictionary<string, string> filters, CancellationToken cancellationToken = default) where T : class;
    Task SetAsync<T>(string collection, string id, T value, CancellationToken cancellationToken = default) where T : class;
    Task<bool> TryCreateAsync<T>(string collection, string id, T value, CancellationToken cancellationToken = default) where T : class;
    Task DeleteAsync(string collection, string id, CancellationToken cancellationToken = default);
}

using Fireman.Contracts.Offline;
using Fireman.Mobile.LocalStorage;
using Fireman.Mobile.Networking;

namespace Fireman.Mobile.SyncEngine;

public interface IOfflineSyncEngine
{
    Task QueueActionAsync(string actionType, string payloadJson);
    Task<OfflineSyncResponse?> SynchronizeAsync();
    Task<int> GetPendingActionCountAsync();
}

public class OfflineSyncEngine : IOfflineSyncEngine
{
    private const string QueueKey = "offline_sync_queue";
    private readonly ILocalDataStore _dataStore;
    private readonly IApiClient _apiClient;

    public OfflineSyncEngine(ILocalDataStore dataStore, IApiClient apiClient)
    {
        _dataStore = dataStore;
        _apiClient = apiClient;
    }

    public async Task QueueActionAsync(string actionType, string payloadJson)
    {
        var queue = await _dataStore.GetAsync<List<OfflineActionDto>>(QueueKey) ?? new List<OfflineActionDto>();
        var action = new OfflineActionDto(
            Guid.NewGuid(),
            actionType,
            payloadJson,
            DateTime.UtcNow,
            "offline_client_hash"
        );
        queue.Add(action);
        await _dataStore.SetAsync(QueueKey, queue);
    }

    public async Task<int> GetPendingActionCountAsync()
    {
        var queue = await _dataStore.GetAsync<List<OfflineActionDto>>(QueueKey);
        return queue?.Count ?? 0;
    }

    public async Task<OfflineSyncResponse?> SynchronizeAsync()
    {
        var queue = await _dataStore.GetAsync<List<OfflineActionDto>>(QueueKey);
        if (queue == null || queue.Count == 0)
            return null;

        var request = new OfflineSyncRequest(Guid.NewGuid(), queue);
        var response = await _apiClient.SyncOfflineActionsAsync(request);

        if (response.Success && response.Data != null)
        {
            // Clear successfully processed items
            await _dataStore.RemoveAsync(QueueKey);
            return response.Data;
        }

        return null;
    }
}

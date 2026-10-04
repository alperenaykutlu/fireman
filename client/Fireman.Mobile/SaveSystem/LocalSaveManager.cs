using System.Text.Json;
using Fireman.Domain.SaveSystem;
using Fireman.Mobile.LocalStorage;

namespace Fireman.Mobile.SaveSystem;

public interface ILocalSaveManager
{
    Task SaveGameAsync(GameSaveData saveData);
    Task<GameSaveData?> LoadGameAsync();
}

public class LocalSaveManager : ILocalSaveManager
{
    private const string SaveKey = "fireman_local_save";
    private readonly ILocalDataStore _dataStore;
    private readonly ISaveMigrationService _migrationService;

    public LocalSaveManager(ILocalDataStore dataStore, ISaveMigrationService migrationService)
    {
        _dataStore = dataStore;
        _migrationService = migrationService;
    }

    public async Task SaveGameAsync(GameSaveData saveData)
    {
        await _dataStore.SetAsync(SaveKey, saveData);
    }

    public async Task<GameSaveData?> LoadGameAsync()
    {
        var raw = await _dataStore.GetAsync<object>(SaveKey);
        if (raw == null)
            return null;

        var json = JsonSerializer.Serialize(raw);
        return _migrationService.MigrateToLatest(json);
    }
}

using Fireman.Contracts.Missions;
using Fireman.Mobile.Networking;
using Fireman.Mobile.SyncEngine;

namespace Fireman.Mobile.ViewModels;

public class MissionsViewModel : BaseViewModel
{
    private readonly IApiClient _apiClient;
    private readonly IOfflineSyncEngine _syncEngine;

    private List<MissionDto> _missions = new();
    public List<MissionDto> Missions
    {
        get => _missions;
        private set => SetProperty(ref _missions, value);
    }

    private string? _statusMessage;
    public string? StatusMessage
    {
        get => _statusMessage;
        private set => SetProperty(ref _statusMessage, value);
    }

    public MissionsViewModel(IApiClient apiClient, IOfflineSyncEngine syncEngine)
    {
        _apiClient = apiClient;
        _syncEngine = syncEngine;
    }

    public async Task LoadMissionsAsync()
    {
        IsBusy = true;
        try
        {
            var response = await _apiClient.GetMissionsAsync();
            if (response.Success && response.Data != null)
            {
                Missions = response.Data.ToList();
            }
            else
            {
                ErrorMessage = response.Message;
            }
        }
        catch (Exception ex)
        {
            ErrorMessage = $"Network error: {ex.Message}";
        }
        finally
        {
            IsBusy = false;
        }
    }

    public async Task<bool> CompleteMissionAsync(Guid missionId, int score, int rescues, int durationSeconds, bool isOnline)
    {
        IsBusy = true;
        try
        {
            if (isOnline)
            {
                var response = await _apiClient.CompleteMissionAsync(new CompleteMissionRequest(missionId, score, rescues, durationSeconds));
                if (response.Success && response.Data != null)
                {
                    StatusMessage = $"Earned {response.Data.EarnedCoins} coins and {response.Data.EarnedXp} XP!";
                    return true;
                }
                ErrorMessage = response.Message;
                return false;
            }
            else
            {
                // Queue for offline synchronization
                await _syncEngine.QueueActionAsync("CompleteMission", $"{{\"MissionId\":\"{missionId}\",\"Score\":{score},\"Rescues\":{rescues}}}");
                StatusMessage = "Mission progress saved locally. Will sync when online.";
                return true;
            }
        }
        finally
        {
            IsBusy = false;
        }
    }
}

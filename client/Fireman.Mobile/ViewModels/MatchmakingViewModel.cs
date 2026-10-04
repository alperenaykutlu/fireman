using Fireman.Contracts.Matches;
using Fireman.Mobile.Networking;
using MatchType = Fireman.Shared.Enums.MatchType;

namespace Fireman.Mobile.ViewModels;

public class MatchmakingViewModel : BaseViewModel
{
    private readonly IApiClient _apiClient;
    private MatchDto? _currentMatch;
    private bool _isSearching;
    private string? _statusMessage;

    public MatchDto? CurrentMatch
    {
        get => _currentMatch;
        private set => SetProperty(ref _currentMatch, value);
    }

    public bool IsSearching
    {
        get => _isSearching;
        private set => SetProperty(ref _isSearching, value);
    }

    public string? StatusMessage
    {
        get => _statusMessage;
        private set => SetProperty(ref _statusMessage, value);
    }

    public MatchmakingViewModel(IApiClient apiClient)
    {
        _apiClient = apiClient;
    }

    public async Task CreateMatchAsync(MatchType type = MatchType.CoopRescue, int maxPlayers = 4)
    {
        IsBusy = true;
        StatusMessage = "Creating match room...";
        try
        {
            var result = await _apiClient.CreateMatchAsync(new CreateMatchRequest(type, maxPlayers));
            if (result.Success && result.Data is not null)
            {
                CurrentMatch = result.Data;
                StatusMessage = $"Match created! Room ID: {result.Data.Id}";
            }
            else
            {
                StatusMessage = result.Message ?? "Failed to create match.";
            }
        }
        catch (Exception ex)
        {
            StatusMessage = $"Error: {ex.Message}";
        }
        finally
        {
            IsBusy = false;
        }
    }

    public async Task JoinMatchAsync(Guid matchId)
    {
        IsBusy = true;
        StatusMessage = "Joining match...";
        try
        {
            var result = await _apiClient.JoinMatchAsync(new JoinMatchRequest(matchId));
            if (result.Success && result.Data is not null)
            {
                CurrentMatch = result.Data;
                StatusMessage = "Successfully joined match!";
            }
            else
            {
                StatusMessage = result.Message ?? "Failed to join match.";
            }
        }
        catch (Exception ex)
        {
            StatusMessage = $"Error: {ex.Message}";
        }
        finally
        {
            IsBusy = false;
        }
    }

    public async Task RefreshMatchStatusAsync()
    {
        if (CurrentMatch is null) return;

        try
        {
            var result = await _apiClient.GetMatchAsync(CurrentMatch.Id);
            if (result.Success && result.Data is not null)
            {
                CurrentMatch = result.Data;
            }
        }
        catch (Exception ex)
        {
            StatusMessage = $"Refresh failed: {ex.Message}";
        }
    }

    public async Task SubmitScoreAsync(int score, int rescues)
    {
        if (CurrentMatch is null) return;

        IsBusy = true;
        try
        {
            var result = await _apiClient.SubmitMatchScoreAsync(new SubmitMatchScoreRequest(CurrentMatch.Id, score, rescues));
            if (result.Success && result.Data is not null)
            {
                CurrentMatch = result.Data;
                StatusMessage = "Score submitted successfully.";
            }
            else
            {
                StatusMessage = result.Message ?? "Failed to submit score.";
            }
        }
        catch (Exception ex)
        {
            StatusMessage = $"Score submission error: {ex.Message}";
        }
        finally
        {
            IsBusy = false;
        }
    }
}

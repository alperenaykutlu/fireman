using System.ComponentModel;
using Fireman.Contracts.Matches;
using Fireman.Mobile.Navigation;
using Fireman.Mobile.ViewModels;
using MatchType = Fireman.Shared.Enums.MatchType;

namespace Fireman.Mobile.Views;

public class LobbyViewBinding : IScreen, IDisposable
{
    private readonly MatchmakingViewModel _viewModel;

    public string ScreenName => "Lobby";
    public bool IsActive { get; private set; }

    public MatchDto? CurrentMatch => _viewModel.CurrentMatch;
    public bool IsSearching => _viewModel.IsSearching;
    public string? StatusText => _viewModel.StatusMessage;

    public event Action? OnLobbyStateChanged;

    public LobbyViewBinding(MatchmakingViewModel viewModel)
    {
        _viewModel = viewModel;
        _viewModel.PropertyChanged += OnViewModelPropertyChanged;
    }

    public Task InitializeAsync()
    {
        return Task.CompletedTask;
    }

    public Task ShowAsync()
    {
        IsActive = true;
        OnLobbyStateChanged?.Invoke();
        return Task.CompletedTask;
    }

    public Task HideAsync()
    {
        IsActive = false;
        return Task.CompletedTask;
    }

    public async Task OnCreateMatchClicked(MatchType type, int maxPlayers)
    {
        await _viewModel.CreateMatchAsync(type, maxPlayers);
    }

    public async Task OnJoinMatchClicked(Guid matchId)
    {
        await _viewModel.JoinMatchAsync(matchId);
    }

    public async Task OnRefreshClicked()
    {
        await _viewModel.RefreshMatchStatusAsync();
    }

    private void OnViewModelPropertyChanged(object? sender, PropertyChangedEventArgs e)
    {
        OnLobbyStateChanged?.Invoke();
    }

    public void Dispose()
    {
        _viewModel.PropertyChanged -= OnViewModelPropertyChanged;
    }
}

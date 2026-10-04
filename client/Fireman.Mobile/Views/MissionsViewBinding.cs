using System.ComponentModel;
using Fireman.Contracts.Missions;
using Fireman.Mobile.ViewModels;

namespace Fireman.Mobile.Views;

public class MissionsViewBinding : IDisposable
{
    private readonly MissionsViewModel _viewModel;

    public IReadOnlyList<MissionDto> MissionsList => _viewModel.Missions;
    public bool IsLoading => _viewModel.IsBusy;
    public string? StatusMessage => _viewModel.StatusMessage;

    public event Action? OnViewUpdated;

    public MissionsViewBinding(MissionsViewModel viewModel)
    {
        _viewModel = viewModel;
        _viewModel.PropertyChanged += OnViewModelPropertyChanged;
    }

    public async Task OnRefreshClicked()
    {
        await _viewModel.LoadMissionsAsync();
    }

    public async Task OnCompleteMissionClicked(Guid missionId, int score, int rescues = 1, int durationSeconds = 60, bool isOnline = true)
    {
        await _viewModel.CompleteMissionAsync(missionId, score, rescues, durationSeconds, isOnline);
    }

    private void OnViewModelPropertyChanged(object? sender, PropertyChangedEventArgs e)
    {
        OnViewUpdated?.Invoke();
    }

    public void Dispose()
    {
        _viewModel.PropertyChanged -= OnViewModelPropertyChanged;
    }
}

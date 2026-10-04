using System.ComponentModel;
using Fireman.Mobile.ViewModels;
using Fireman.Shared.Enums;

namespace Fireman.Mobile.Views;

public class CharacterCustomizationViewBinding : IDisposable
{
    private readonly CharacterCustomizationViewModel _viewModel;

    public string DisplayName { get; private set; } = string.Empty;
    public int DisplayLevel { get; private set; }
    public long DisplayExperience { get; private set; }
    public bool IsLoadingIndicatorVisible { get; private set; }
    public string? FeedbackText { get; private set; }

    public event Action? OnViewUpdated;

    public CharacterCustomizationViewBinding(CharacterCustomizationViewModel viewModel)
    {
        _viewModel = viewModel;
        _viewModel.PropertyChanged += OnViewModelPropertyChanged;
        UpdateStateFromViewModel();
    }

    public async Task OnEquipButtonClicked(CharacterSlot slot, Guid itemId)
    {
        await _viewModel.EquipItemAsync(slot, itemId);
    }

    private void OnViewModelPropertyChanged(object? sender, PropertyChangedEventArgs e)
    {
        UpdateStateFromViewModel();
        OnViewUpdated?.Invoke();
    }

    private void UpdateStateFromViewModel()
    {
        IsLoadingIndicatorVisible = _viewModel.IsBusy;
        FeedbackText = _viewModel.ErrorMessage;

        if (_viewModel.Character is not null)
        {
            DisplayName = _viewModel.Character.Name;
            DisplayLevel = _viewModel.Character.Level;
            DisplayExperience = _viewModel.Character.Experience;
        }
    }

    public void Dispose()
    {
        _viewModel.PropertyChanged -= OnViewModelPropertyChanged;
    }
}

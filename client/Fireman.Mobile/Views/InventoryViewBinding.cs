using System.ComponentModel;
using Fireman.Contracts.Inventory;
using Fireman.Mobile.Navigation;
using Fireman.Mobile.ViewModels;

namespace Fireman.Mobile.Views;

public class InventoryViewBinding : IScreen, IDisposable
{
    private readonly InventoryViewModel _viewModel;

    public string ScreenName => "Inventory";
    public bool IsActive { get; private set; }

    public IReadOnlyList<InventoryItemDto> Items => _viewModel.Items;
    public bool IsLoading => _viewModel.IsBusy;
    public string? ErrorMessage => _viewModel.ErrorMessage;

    public event Action? OnInventoryUpdated;

    public InventoryViewBinding(InventoryViewModel viewModel)
    {
        _viewModel = viewModel;
        _viewModel.PropertyChanged += OnViewModelPropertyChanged;
    }

    public async Task InitializeAsync()
    {
        await _viewModel.LoadInventoryAsync();
    }

    public Task ShowAsync()
    {
        IsActive = true;
        OnInventoryUpdated?.Invoke();
        return Task.CompletedTask;
    }

    public Task HideAsync()
    {
        IsActive = false;
        return Task.CompletedTask;
    }

    public async Task OnBuyItemClicked(Guid itemDefinitionId, int quantity = 1)
    {
        await _viewModel.BuyItemAsync(itemDefinitionId, quantity);
    }

    private void OnViewModelPropertyChanged(object? sender, PropertyChangedEventArgs e)
    {
        OnInventoryUpdated?.Invoke();
    }

    public void Dispose()
    {
        _viewModel.PropertyChanged -= OnViewModelPropertyChanged;
    }
}

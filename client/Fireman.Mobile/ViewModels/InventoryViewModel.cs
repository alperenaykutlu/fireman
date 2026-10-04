using Fireman.Contracts.Inventory;
using Fireman.Mobile.Networking;

namespace Fireman.Mobile.ViewModels;

public class InventoryViewModel : BaseViewModel
{
    private readonly IApiClient _apiClient;

    private List<InventoryItemDto> _items = new();
    public List<InventoryItemDto> Items
    {
        get => _items;
        private set => SetProperty(ref _items, value);
    }

    public InventoryViewModel(IApiClient apiClient)
    {
        _apiClient = apiClient;
    }

    public async Task LoadInventoryAsync()
    {
        IsBusy = true;
        try
        {
            var response = await _apiClient.GetInventoryAsync();
            if (response.Success && response.Data != null)
            {
                Items = response.Data.ToList();
            }
            else
            {
                ErrorMessage = response.Message;
            }
        }
        catch (Exception ex)
        {
            ErrorMessage = ex.Message;
        }
        finally
        {
            IsBusy = false;
        }
    }

    public async Task<bool> BuyItemAsync(Guid itemDefinitionId, int quantity = 1)
    {
        IsBusy = true;
        try
        {
            var response = await _apiClient.BuyItemAsync(new BuyItemRequest(itemDefinitionId, quantity));
            if (response.Success && response.Data != null)
            {
                await LoadInventoryAsync();
                return true;
            }

            ErrorMessage = response.Message;
            return false;
        }
        finally
        {
            IsBusy = false;
        }
    }
}

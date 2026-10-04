using Fireman.Contracts.Characters;
using Fireman.Contracts.Inventory;
using Fireman.Mobile.Networking;
using Fireman.Shared.Enums;

namespace Fireman.Mobile.ViewModels;

public class CharacterCustomizationViewModel : BaseViewModel
{
    private readonly IApiClient _apiClient;

    private CharacterDto? _character;
    public CharacterDto? Character
    {
        get => _character;
        private set => SetProperty(ref _character, value);
    }

    private List<InventoryItemDto> _availableHats = new();
    public List<InventoryItemDto> AvailableHats
    {
        get => _availableHats;
        private set => SetProperty(ref _availableHats, value);
    }

    public CharacterCustomizationViewModel(IApiClient apiClient)
    {
        _apiClient = apiClient;
    }

    public async Task LoadCharacterAsync()
    {
        IsBusy = true;
        ErrorMessage = null;
        try
        {
            var charResponse = await _apiClient.GetCharacterAsync();
            if (charResponse.Success && charResponse.Data != null)
            {
                Character = charResponse.Data;
            }
            else
            {
                ErrorMessage = charResponse.Message;
            }

            var invResponse = await _apiClient.GetInventoryAsync();
            if (invResponse.Success && invResponse.Data != null)
            {
                AvailableHats = invResponse.Data
                    .Where(i => i.CompatibleSlot == CharacterSlot.Hat)
                    .ToList();
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

    public async Task<bool> SelectHatAsync(InventoryItemDto hatItem)
    {
        if (hatItem.CompatibleSlot != CharacterSlot.Hat)
        {
            ErrorMessage = "Selected item is not a hat!";
            return false;
        }

        IsBusy = true;
        try
        {
            var response = await _apiClient.EquipItemAsync(new EquipItemRequest(CharacterSlot.Hat, hatItem.ItemDefinitionId));
            if (response.Success && response.Data != null)
            {
                Character = response.Data;
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

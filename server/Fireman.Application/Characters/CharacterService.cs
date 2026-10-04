using Fireman.Application.Common.Interfaces;
using Fireman.Application.Policies;
using Fireman.Contracts.Characters;
using Fireman.Domain.Characters;
using Fireman.Domain.Inventory;
using Fireman.Domain.Policies;
using Fireman.Domain.Users;
using Fireman.Shared.Enums;
using Fireman.Shared.Results;

namespace Fireman.Application.Characters;

public interface ICharacterService
{
    Task<Result<CharacterDto>> GetCharacterAsync(CancellationToken cancellationToken = default);
    Task<Result<CharacterDto>> EquipItemAsync(EquipItemRequest request, CancellationToken cancellationToken = default);
    Task<Result<CharacterDto>> UnequipItemAsync(UnequipItemRequest request, CancellationToken cancellationToken = default);
}

public class CharacterService : ICharacterService
{
    private readonly ICharacterRepository _characterRepository;
    private readonly IUserRepository _userRepository;
    private readonly IInventoryRepository _inventoryRepository;
    private readonly IItemDefinitionRepository _itemDefinitionRepository;
    private readonly IGamePolicy<CanEquipItemContext> _canEquipItemPolicy;
    private readonly ICurrentUser _currentUser;
    private readonly IUnitOfWork _unitOfWork;

    public CharacterService(
        ICharacterRepository characterRepository,
        IUserRepository userRepository,
        IInventoryRepository inventoryRepository,
        IItemDefinitionRepository itemDefinitionRepository,
        IGamePolicy<CanEquipItemContext> canEquipItemPolicy,
        ICurrentUser currentUser,
        IUnitOfWork unitOfWork)
    {
        _characterRepository = characterRepository;
        _userRepository = userRepository;
        _inventoryRepository = inventoryRepository;
        _itemDefinitionRepository = itemDefinitionRepository;
        _canEquipItemPolicy = canEquipItemPolicy;
        _currentUser = currentUser;
        _unitOfWork = unitOfWork;
    }

    public async Task<Result<CharacterDto>> GetCharacterAsync(CancellationToken cancellationToken = default)
    {
        if (!_currentUser.UserId.HasValue)
            return Result.Failure<CharacterDto>("Auth.Unauthorized", "User is not authenticated.");

        var character = await _characterRepository.GetByUserIdAsync(_currentUser.UserId.Value, cancellationToken);
        if (character is null)
            return Result.Failure<CharacterDto>("Character.NotFound", "Character not found.");

        return Result.Success(await MapToDto(character, cancellationToken));
    }

    public async Task<Result<CharacterDto>> EquipItemAsync(EquipItemRequest request, CancellationToken cancellationToken = default)
    {
        if (!_currentUser.UserId.HasValue)
            return Result.Failure<CharacterDto>("Auth.Unauthorized", "User is not authenticated.");

        var user = await _userRepository.GetByIdAsync(_currentUser.UserId.Value, cancellationToken);
        var character = await _characterRepository.GetByUserIdAsync(_currentUser.UserId.Value, cancellationToken);
        var itemDef = await _itemDefinitionRepository.GetByIdAsync(request.ItemDefinitionId, cancellationToken);

        if (user is null || character is null)
            return Result.Failure<CharacterDto>("Character.NotFound", "Character not found.");

        if (itemDef is null)
            return Result.Failure<CharacterDto>("Item.NotFound", "Item not found.");

        // Check ownership in inventory (Server authoritative - Section 24)
        var ownership = await _inventoryRepository.GetByUserAndItemDefinitionIdAsync(user.Id, itemDef.Id, cancellationToken);

        var policyResult = _canEquipItemPolicy.Evaluate(new CanEquipItemContext(
            user,
            character,
            itemDef,
            ownership,
            request.Slot));

        if (!policyResult.IsAllowed)
            return Result.Failure<CharacterDto>("Character.CannotEquip", policyResult.Reason ?? "Cannot equip item.");

        character.EquipItem(request.Slot, itemDef.Id);
        await _characterRepository.UpdateAsync(character, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return Result.Success(await MapToDto(character, cancellationToken));
    }

    public async Task<Result<CharacterDto>> UnequipItemAsync(UnequipItemRequest request, CancellationToken cancellationToken = default)
    {
        if (!_currentUser.UserId.HasValue)
            return Result.Failure<CharacterDto>("Auth.Unauthorized", "User is not authenticated.");

        var character = await _characterRepository.GetByUserIdAsync(_currentUser.UserId.Value, cancellationToken);
        if (character is null)
            return Result.Failure<CharacterDto>("Character.NotFound", "Character not found.");

        character.UnequipItem(request.Slot);
        await _characterRepository.UpdateAsync(character, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return Result.Success(await MapToDto(character, cancellationToken));
    }

    private async Task<CharacterDto> MapToDto(Character character, CancellationToken ct)
    {
        var equippedDtos = new List<EquippedItemDto>();
        foreach (var eq in character.EquippedItems)
        {
            var def = await _itemDefinitionRepository.GetByIdAsync(eq.ItemDefinitionId, ct);
            equippedDtos.Add(new EquippedItemDto(
                eq.Slot,
                eq.ItemDefinitionId,
                def?.Name ?? "Unknown Item",
                def?.AssetId ?? "default_asset",
                eq.EquippedAt));
        }

        return new CharacterDto(
            character.Id,
            character.UserId,
            character.Name,
            character.Gender,
            character.Level,
            character.Experience,
            equippedDtos);
    }
}

using Fireman.Application.Common.Interfaces;
using Fireman.Application.Events;
using Fireman.Application.Policies;
using Fireman.Application.Strategies.Pricing;
using Fireman.Contracts.Inventory;
using Fireman.Domain.Economy;
using Fireman.Domain.Inventory;
using Fireman.Domain.Policies;
using Fireman.Domain.Users;
using Fireman.Shared.Results;

namespace Fireman.Application.Inventory;

public interface IInventoryService
{
    Task<Result<IReadOnlyList<ItemDefinitionDto>>> GetAvailableShopItemsAsync(CancellationToken cancellationToken = default);
    Task<Result<IReadOnlyList<InventoryItemDto>>> GetUserInventoryAsync(CancellationToken cancellationToken = default);
    Task<Result<InventoryItemDto>> BuyItemAsync(BuyItemRequest request, CancellationToken cancellationToken = default);
}

public class InventoryService : IInventoryService
{
    private readonly IInventoryRepository _inventoryRepository;
    private readonly IItemDefinitionRepository _itemDefinitionRepository;
    private readonly IUserRepository _userRepository;
    private readonly IWalletRepository _walletRepository;
    private readonly ICurrencyLedgerRepository _ledgerRepository;
    private readonly IPricingStrategyFactory _pricingStrategyFactory;
    private readonly IGamePolicy<CanBuyItemContext> _canBuyItemPolicy;
    private readonly IEventBus _eventBus;
    private readonly ICurrentUser _currentUser;
    private readonly IUnitOfWork _unitOfWork;

    public InventoryService(
        IInventoryRepository inventoryRepository,
        IItemDefinitionRepository itemDefinitionRepository,
        IUserRepository userRepository,
        IWalletRepository walletRepository,
        ICurrencyLedgerRepository ledgerRepository,
        IPricingStrategyFactory pricingStrategyFactory,
        IGamePolicy<CanBuyItemContext> canBuyItemPolicy,
        IEventBus eventBus,
        ICurrentUser currentUser,
        IUnitOfWork unitOfWork)
    {
        _inventoryRepository = inventoryRepository;
        _itemDefinitionRepository = itemDefinitionRepository;
        _userRepository = userRepository;
        _walletRepository = walletRepository;
        _ledgerRepository = ledgerRepository;
        _pricingStrategyFactory = pricingStrategyFactory;
        _canBuyItemPolicy = canBuyItemPolicy;
        _eventBus = eventBus;
        _currentUser = currentUser;
        _unitOfWork = unitOfWork;
    }

    public async Task<Result<IReadOnlyList<ItemDefinitionDto>>> GetAvailableShopItemsAsync(CancellationToken cancellationToken = default)
    {
        var items = await _itemDefinitionRepository.GetAllAsync(cancellationToken);
        var dtos = items.Select(i => new ItemDefinitionDto(
            i.Id,
            i.Name,
            i.Description,
            i.Type,
            i.Rarity,
            i.CompatibleSlot,
            i.Price,
            i.CurrencyType,
            i.IsPurchasable,
            i.AssetId
        )).ToList();

        return Result.Success<IReadOnlyList<ItemDefinitionDto>>(dtos);
    }

    public async Task<Result<IReadOnlyList<InventoryItemDto>>> GetUserInventoryAsync(CancellationToken cancellationToken = default)
    {
        if (!_currentUser.UserId.HasValue)
            return Result.Failure<IReadOnlyList<InventoryItemDto>>("Auth.Unauthorized", "User is not authenticated.");

        var items = await _inventoryRepository.GetByUserIdAsync(_currentUser.UserId.Value, cancellationToken);
        var dtos = new List<InventoryItemDto>();

        foreach (var invItem in items)
        {
            var def = await _itemDefinitionRepository.GetByIdAsync(invItem.ItemDefinitionId, cancellationToken);
            if (def is not null)
            {
                dtos.Add(new InventoryItemDto(
                    invItem.Id,
                    invItem.ItemDefinitionId,
                    def.Name,
                    def.Type,
                    def.Rarity,
                    def.CompatibleSlot,
                    invItem.Quantity,
                    invItem.AcquiredAt));
            }
        }

        return Result.Success<IReadOnlyList<InventoryItemDto>>(dtos);
    }

    public async Task<Result<InventoryItemDto>> BuyItemAsync(BuyItemRequest request, CancellationToken cancellationToken = default)
    {
        if (!_currentUser.UserId.HasValue)
            return Result.Failure<InventoryItemDto>("Auth.Unauthorized", "User is not authenticated.");

        var user = await _userRepository.GetByIdAsync(_currentUser.UserId.Value, cancellationToken);
        var wallet = await _walletRepository.GetByUserIdAsync(_currentUser.UserId.Value, cancellationToken);
        var itemDef = await _itemDefinitionRepository.GetByIdAsync(request.ItemDefinitionId, cancellationToken);

        if (user is null || wallet is null)
            return Result.Failure<InventoryItemDto>("User.NotFound", "User account or wallet not found.");

        if (itemDef is null)
            return Result.Failure<InventoryItemDto>("Item.NotFound", "Item not found.");

        // Apply pricing strategy (role-based VIP discounts)
        var pricingStrategy = _pricingStrategyFactory.GetStrategy(user.Role);
        var pricingResult = pricingStrategy.CalculatePrice(new PricingContext(user.Role, itemDef.Price * request.Quantity));

        // Evaluate policy
        var policyResult = _canBuyItemPolicy.Evaluate(new CanBuyItemContext(
            user,
            wallet,
            itemDef,
            request.Quantity,
            pricingResult.FinalPrice));

        if (!policyResult.IsAllowed)
            return Result.Failure<InventoryItemDto>("Inventory.CannotBuy", policyResult.Reason ?? "Cannot buy item.");

        // Deduct currency and log to ledger
        wallet.DeductCurrency(itemDef.CurrencyType, pricingResult.FinalPrice);
        var ledgerEntry = new CurrencyLedgerEntry(
            user.Id,
            itemDef.CurrencyType,
            -pricingResult.FinalPrice,
            $"Bought {request.Quantity}x {itemDef.Name} ({pricingResult.AppliedPricing})",
            itemDef.CurrencyType == Shared.Enums.CurrencyType.Coins ? wallet.Coins : wallet.Gems);

        await _walletRepository.UpdateAsync(wallet, cancellationToken);
        await _ledgerRepository.AddEntryAsync(ledgerEntry, cancellationToken);

        // Add or update inventory item
        var existingInventoryItem = await _inventoryRepository.GetByUserAndItemDefinitionIdAsync(user.Id, itemDef.Id, cancellationToken);
        InventoryItem finalInventoryItem;

        if (existingInventoryItem is not null)
        {
            existingInventoryItem.AddQuantity(request.Quantity);
            await _inventoryRepository.UpdateAsync(existingInventoryItem, cancellationToken);
            finalInventoryItem = existingInventoryItem;
        }
        else
        {
            finalInventoryItem = InventoryItem.Create(user.Id, itemDef.Id, request.Quantity);
            await _inventoryRepository.AddAsync(finalInventoryItem, cancellationToken);
        }

        await _unitOfWork.SaveChangesAsync(cancellationToken);

        // Publish event to decoupled handlers (Analytics, etc.)
        await _eventBus.PublishAsync(new ItemPurchasedEvent(
            user.Id,
            itemDef.Id,
            pricingResult.FinalPrice,
            request.Quantity), cancellationToken);

        return Result.Success(new InventoryItemDto(
            finalInventoryItem.Id,
            itemDef.Id,
            itemDef.Name,
            itemDef.Type,
            itemDef.Rarity,
            itemDef.CompatibleSlot,
            finalInventoryItem.Quantity,
            finalInventoryItem.AcquiredAt));
    }
}

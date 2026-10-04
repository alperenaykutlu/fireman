namespace Fireman.Domain.Inventory;

public interface IInventoryRepository
{
    Task<IReadOnlyList<InventoryItem>> GetByUserIdAsync(Guid userId, CancellationToken cancellationToken = default);
    Task<InventoryItem?> GetByUserAndItemDefinitionIdAsync(Guid userId, Guid itemDefinitionId, CancellationToken cancellationToken = default);
    Task AddAsync(InventoryItem item, CancellationToken cancellationToken = default);
    Task UpdateAsync(InventoryItem item, CancellationToken cancellationToken = default);
    Task RemoveAsync(InventoryItem item, CancellationToken cancellationToken = default);
}

public interface IItemDefinitionRepository
{
    Task<IReadOnlyList<ItemDefinition>> GetAllAsync(CancellationToken cancellationToken = default);
    Task<ItemDefinition?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task AddAsync(ItemDefinition itemDefinition, CancellationToken cancellationToken = default);
}

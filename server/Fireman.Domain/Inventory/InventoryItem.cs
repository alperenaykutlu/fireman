using Fireman.Domain.Common;
using Fireman.Shared.Exceptions;

namespace Fireman.Domain.Inventory;

public class InventoryItem : AggregateRoot<Guid>
{
    public Guid UserId { get; private set; }
    public Guid ItemDefinitionId { get; private set; }
    public int Quantity { get; private set; }
    public DateTime AcquiredAt { get; private set; }

    private InventoryItem() { }

    public static InventoryItem Create(Guid userId, Guid itemDefinitionId, int quantity = 1)
    {
        if (quantity <= 0)
            throw new ValidationException("Quantity must be greater than zero.");

        return new InventoryItem
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            ItemDefinitionId = itemDefinitionId,
            Quantity = quantity,
            AcquiredAt = DateTime.UtcNow,
            CreatedAt = DateTime.UtcNow
        };
    }

    public void AddQuantity(int amount)
    {
        if (amount <= 0)
            throw new ValidationException("Amount to add must be positive.");

        Quantity += amount;
        UpdatedAt = DateTime.UtcNow;
    }

    public void ConsumeQuantity(int amount)
    {
        if (amount <= 0)
            throw new ValidationException("Amount to consume must be positive.");

        if (Quantity < amount)
            throw new ValidationException("Insufficient item quantity in inventory.");

        Quantity -= amount;
        UpdatedAt = DateTime.UtcNow;
    }
}

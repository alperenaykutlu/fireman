using Fireman.Application.Common.Interfaces;
using Fireman.Domain.Characters;
using Fireman.Domain.Inventory;
using Fireman.Domain.Users;

namespace Fireman.Infrastructure.Persistence.Repositories;

public sealed class UserRepository(IDocumentDatabase database) : IUserRepository
{
    private const string Collection = "users";
    public Task<User?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) => database.GetAsync<User>(Collection, id.ToString(), cancellationToken);
    public async Task<User?> GetByNormalizedUsernameAsync(string normalizedUsername, CancellationToken cancellationToken = default) =>
        (await database.FindAsync<User>(Collection, new Dictionary<string, string> { ["normalizedUsername"] = normalizedUsername }, cancellationToken)).FirstOrDefault();
    public async Task<User?> GetByEmailAsync(string email, CancellationToken cancellationToken = default) =>
        (await database.FindAsync<User>(Collection, new Dictionary<string, string> { ["email"] = email }, cancellationToken)).FirstOrDefault();
    public async Task<bool> ExistsByNormalizedUsernameAsync(string normalizedUsername, CancellationToken cancellationToken = default) =>
        (await database.FindAsync<User>(Collection, new Dictionary<string, string> { ["normalizedUsername"] = normalizedUsername }, cancellationToken)).Count > 0;
    public async Task<bool> ExistsByEmailAsync(string email, CancellationToken cancellationToken = default) =>
        (await database.FindAsync<User>(Collection, new Dictionary<string, string> { ["email"] = email }, cancellationToken)).Count > 0;
    public Task AddAsync(User user, CancellationToken cancellationToken = default) => database.SetAsync(Collection, user.Id.ToString(), user, cancellationToken);
    public Task UpdateAsync(User user, CancellationToken cancellationToken = default) => database.SetAsync(Collection, user.Id.ToString(), user, cancellationToken);
}

public sealed class CharacterRepository(IDocumentDatabase database) : ICharacterRepository
{
    private const string Collection = "characters";
    public Task<Character?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) => database.GetAsync<Character>(Collection, id.ToString(), cancellationToken);
    public async Task<Character?> GetByUserIdAsync(Guid userId, CancellationToken cancellationToken = default) =>
        (await database.FindAsync<Character>(Collection, new Dictionary<string, string> { ["userId"] = userId.ToString() }, cancellationToken)).FirstOrDefault();
    public Task AddAsync(Character character, CancellationToken cancellationToken = default) => database.SetAsync(Collection, character.Id.ToString(), character, cancellationToken);
    public Task UpdateAsync(Character character, CancellationToken cancellationToken = default) => database.SetAsync(Collection, character.Id.ToString(), character, cancellationToken);
}

public sealed class InventoryRepository(IDocumentDatabase database) : IInventoryRepository
{
    private const string Collection = "inventoryItems";
    public async Task<IReadOnlyList<InventoryItem>> GetByUserIdAsync(Guid userId, CancellationToken cancellationToken = default) =>
        await database.FindAsync<InventoryItem>(Collection, new Dictionary<string, string> { ["userId"] = userId.ToString() }, cancellationToken);
    public async Task<InventoryItem?> GetByUserAndItemDefinitionIdAsync(Guid userId, Guid itemDefinitionId, CancellationToken cancellationToken = default) =>
        (await database.FindAsync<InventoryItem>(Collection, new Dictionary<string, string> { ["userId"] = userId.ToString(), ["itemDefinitionId"] = itemDefinitionId.ToString() }, cancellationToken)).FirstOrDefault();
    public Task AddAsync(InventoryItem item, CancellationToken cancellationToken = default) => database.SetAsync(Collection, item.Id.ToString(), item, cancellationToken);
    public Task UpdateAsync(InventoryItem item, CancellationToken cancellationToken = default) => database.SetAsync(Collection, item.Id.ToString(), item, cancellationToken);
    public Task RemoveAsync(InventoryItem item, CancellationToken cancellationToken = default) => database.DeleteAsync(Collection, item.Id.ToString(), cancellationToken);
}

public sealed class ItemDefinitionRepository(IDocumentDatabase database) : IItemDefinitionRepository
{
    private const string Collection = "itemDefinitions";
    public Task<IReadOnlyList<ItemDefinition>> GetAllAsync(CancellationToken cancellationToken = default) => database.GetAllAsync<ItemDefinition>(Collection, cancellationToken);
    public Task<ItemDefinition?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) => database.GetAsync<ItemDefinition>(Collection, id.ToString(), cancellationToken);
    public Task AddAsync(ItemDefinition itemDefinition, CancellationToken cancellationToken = default) => database.SetAsync(Collection, itemDefinition.Id.ToString(), itemDefinition, cancellationToken);
}

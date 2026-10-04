using Fireman.Domain.Characters;
using Fireman.Domain.Economy;
using Fireman.Domain.Inventory;
using Fireman.Domain.Matches;
using Fireman.Domain.Missions;
using Fireman.Domain.Users;
using Fireman.Infrastructure.Persistence;

namespace Fireman.Infrastructure.Persistence.Repositories;

public class UserRepository : IUserRepository
{
    private readonly InMemoryDbContext _context;

    public UserRepository(InMemoryDbContext context) => _context = context;

    public Task<User?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) =>
        Task.FromResult(_context.Users.GetValueOrDefault(id));

    public Task<User?> GetByNormalizedUsernameAsync(string normalizedUsername, CancellationToken cancellationToken = default) =>
        Task.FromResult(_context.Users.Values.FirstOrDefault(u => u.NormalizedUsername == normalizedUsername));

    public Task<User?> GetByEmailAsync(string email, CancellationToken cancellationToken = default) =>
        Task.FromResult(_context.Users.Values.FirstOrDefault(u => u.Email.Equals(email, StringComparison.OrdinalIgnoreCase)));

    public Task<bool> ExistsByNormalizedUsernameAsync(string normalizedUsername, CancellationToken cancellationToken = default) =>
        Task.FromResult(_context.Users.Values.Any(u => u.NormalizedUsername == normalizedUsername));

    public Task<bool> ExistsByEmailAsync(string email, CancellationToken cancellationToken = default) =>
        Task.FromResult(_context.Users.Values.Any(u => u.Email.Equals(email, StringComparison.OrdinalIgnoreCase)));

    public Task AddAsync(User user, CancellationToken cancellationToken = default)
    {
        _context.Users[user.Id] = user;
        return Task.CompletedTask;
    }

    public Task UpdateAsync(User user, CancellationToken cancellationToken = default)
    {
        _context.Users[user.Id] = user;
        return Task.CompletedTask;
    }
}

public class CharacterRepository : ICharacterRepository
{
    private readonly InMemoryDbContext _context;

    public CharacterRepository(InMemoryDbContext context) => _context = context;

    public Task<Character?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) =>
        Task.FromResult(_context.Characters.GetValueOrDefault(id));

    public Task<Character?> GetByUserIdAsync(Guid userId, CancellationToken cancellationToken = default) =>
        Task.FromResult(_context.Characters.Values.FirstOrDefault(c => c.UserId == userId));

    public Task AddAsync(Character character, CancellationToken cancellationToken = default)
    {
        _context.Characters[character.Id] = character;
        return Task.CompletedTask;
    }

    public Task UpdateAsync(Character character, CancellationToken cancellationToken = default)
    {
        _context.Characters[character.Id] = character;
        return Task.CompletedTask;
    }
}

public class InventoryRepository : IInventoryRepository
{
    private readonly InMemoryDbContext _context;

    public InventoryRepository(InMemoryDbContext context) => _context = context;

    public Task<IReadOnlyList<InventoryItem>> GetByUserIdAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        var items = _context.InventoryItems.Values.Where(i => i.UserId == userId).ToList();
        return Task.FromResult<IReadOnlyList<InventoryItem>>(items);
    }

    public Task<InventoryItem?> GetByUserAndItemDefinitionIdAsync(Guid userId, Guid itemDefinitionId, CancellationToken cancellationToken = default) =>
        Task.FromResult(_context.InventoryItems.Values.FirstOrDefault(i => i.UserId == userId && i.ItemDefinitionId == itemDefinitionId));

    public Task AddAsync(InventoryItem item, CancellationToken cancellationToken = default)
    {
        _context.InventoryItems[item.Id] = item;
        return Task.CompletedTask;
    }

    public Task UpdateAsync(InventoryItem item, CancellationToken cancellationToken = default)
    {
        _context.InventoryItems[item.Id] = item;
        return Task.CompletedTask;
    }

    public Task RemoveAsync(InventoryItem item, CancellationToken cancellationToken = default)
    {
        _context.InventoryItems.TryRemove(item.Id, out _);
        return Task.CompletedTask;
    }
}

public class ItemDefinitionRepository : IItemDefinitionRepository
{
    private readonly InMemoryDbContext _context;

    public ItemDefinitionRepository(InMemoryDbContext context) => _context = context;

    public Task<IReadOnlyList<ItemDefinition>> GetAllAsync(CancellationToken cancellationToken = default)
    {
        var items = _context.ItemDefinitions.Values.ToList();
        return Task.FromResult<IReadOnlyList<ItemDefinition>>(items);
    }

    public Task<ItemDefinition?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) =>
        Task.FromResult(_context.ItemDefinitions.GetValueOrDefault(id));

    public Task AddAsync(ItemDefinition itemDefinition, CancellationToken cancellationToken = default)
    {
        _context.ItemDefinitions[itemDefinition.Id] = itemDefinition;
        return Task.CompletedTask;
    }
}

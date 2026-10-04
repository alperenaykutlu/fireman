using Fireman.Domain.Common;
using Fireman.Shared.Enums;
using Fireman.Shared.Exceptions;

namespace Fireman.Domain.Characters;

public class Character : AggregateRoot<Guid>
{
    private readonly List<CharacterEquipment> _equippedItems = new();

    public Guid UserId { get; private set; }
    public string Name { get; private set; } = string.Empty;
    public CharacterGender Gender { get; private set; }
    public int Level { get; private set; } = 1;
    public long Experience { get; private set; } = 0;
    public IReadOnlyCollection<CharacterEquipment> EquippedItems => _equippedItems.AsReadOnly();

    private Character() { }

    public static Character Create(Guid userId, string name, CharacterGender gender)
    {
        if (string.IsNullOrWhiteSpace(name))
            throw new ValidationException("Character name cannot be empty.");

        var character = new Character
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Name = name.Trim(),
            Gender = gender,
            Level = 1,
            Experience = 0,
            CreatedAt = DateTime.UtcNow
        };

        return character;
    }

    public void EquipItem(CharacterSlot slot, Guid itemDefinitionId)
    {
        // Remove existing item in the slot if present
        _equippedItems.RemoveAll(e => e.Slot == slot);

        _equippedItems.Add(new CharacterEquipment(Id, slot, itemDefinitionId));
        UpdatedAt = DateTime.UtcNow;
    }

    public void UnequipItem(CharacterSlot slot)
    {
        var removed = _equippedItems.RemoveAll(e => e.Slot == slot);
        if (removed > 0)
        {
            UpdatedAt = DateTime.UtcNow;
        }
    }

    public bool AddExperience(long expGained, out int newLevel)
    {
        if (expGained < 0)
            throw new ValidationException("Experience gained cannot be negative.");

        Experience += expGained;
        int calculatedLevel = 1 + (int)(Experience / 1000); // 1000 XP per level
        bool leveledUp = calculatedLevel > Level;

        if (leveledUp)
        {
            Level = calculatedLevel;
        }

        UpdatedAt = DateTime.UtcNow;
        newLevel = Level;
        return leveledUp;
    }
}

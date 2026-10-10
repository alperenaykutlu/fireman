namespace Fireman.Domain.Social;

public enum ClanRole : byte
{
    Member = 1,
    Elder = 2,
    CoLeader = 3,
    Leader = 4
}

public class Clan
{
    public Guid Id { get; private set; }
    public string Name { get; private set; } = string.Empty;
    public string Tag { get; private set; } = string.Empty; // e.g. [FIRE]
    public string Description { get; private set; } = string.Empty;
    public string BadgeIcon { get; private set; } = "badge_flame_1";
    public int Level { get; private set; } = 1;
    public long ExperiencePoints { get; private set; } = 0;
    public int RequiredTrophies { get; private set; } = 0;
    public bool IsOpen { get; private set; } = true;
    public DateTime CreatedAt { get; private set; }

    private readonly List<ClanMember> _members = new();
    public IReadOnlyCollection<ClanMember> Members => _members.AsReadOnly();

    private Clan() { }

    public Clan(string name, string tag, string description, Guid leaderUserId, string badgeIcon = "badge_flame_1")
    {
        Id = Guid.NewGuid();
        Name = name.Trim();
        Tag = tag.Trim().ToUpperInvariant();
        Description = description.Trim();
        BadgeIcon = badgeIcon;
        CreatedAt = DateTime.UtcNow;

        _members.Add(new ClanMember(Id, leaderUserId, ClanRole.Leader));
    }

    public void AddMember(Guid userId, ClanRole role = ClanRole.Member)
    {
        if (_members.Count >= 50)
            throw new InvalidOperationException("Klan azami üye kapasitesine (50) ulaştı.");

        if (_members.Any(m => m.UserId == userId))
            throw new InvalidOperationException("Kullanıcı zaten bu klanın üyesi.");

        _members.Add(new ClanMember(Id, userId, role));
    }

    public void RemoveMember(Guid userId)
    {
        var member = _members.FirstOrDefault(m => m.UserId == userId);
        if (member is null)
            throw new InvalidOperationException("Kullanıcı bu klanın üyesi değil.");

        if (member.Role == ClanRole.Leader && _members.Count > 1)
            throw new InvalidOperationException("Klan lideri ayrılmadan önce liderliği devretmelidir.");

        _members.Remove(member);
    }
}

public class ClanMember
{
    public Guid Id { get; private set; }
    public Guid ClanId { get; private set; }
    public Guid UserId { get; private set; }
    public ClanRole Role { get; private set; }
    public DateTime JoinedAt { get; private set; }

    private ClanMember() { }

    public ClanMember(Guid clanId, Guid userId, ClanRole role)
    {
        Id = Guid.NewGuid();
        ClanId = clanId;
        UserId = userId;
        Role = role;
        JoinedAt = DateTime.UtcNow;
    }

    public void Promote(ClanRole newRole)
    {
        Role = newRole;
    }
}

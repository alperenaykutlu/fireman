using Fireman.Domain.Common;
using Fireman.Shared.Enums;
using Fireman.Shared.Exceptions;
using MatchType = Fireman.Shared.Enums.MatchType;

namespace Fireman.Domain.Matches;

public class MatchPlayer : Entity<Guid>
{
    public Guid MatchId { get; private set; }
    public Guid UserId { get; private set; }
    public string Username { get; private set; }
    public int Score { get; private set; }
    public int Rescues { get; private set; }
    public bool IsReady { get; private set; }

    public MatchPlayer(Guid matchId, Guid userId, string username)
    {
        Id = Guid.NewGuid();
        MatchId = matchId;
        UserId = userId;
        Username = username;
        Score = 0;
        Rescues = 0;
        IsReady = false;
        CreatedAt = DateTime.UtcNow;
    }

    public void SetReady(bool ready) => IsReady = ready;

    public void AddScore(int score, int rescues)
    {
        Score += score;
        Rescues += rescues;
        UpdatedAt = DateTime.UtcNow;
    }
}

public class Match : AggregateRoot<Guid>
{
    private readonly List<MatchPlayer> _players = new();

    public MatchType Type { get; private set; }
    public MatchStatus Status { get; private set; }
    public Guid HostUserId { get; private set; }
    public int MaxPlayers { get; private set; }
    public string RoomName { get; private set; } = string.Empty;
    public string? PasswordHash { get; private set; }
    public DateTime? StartedAt { get; private set; }
    public DateTime? FinishedAt { get; private set; }
    public IReadOnlyCollection<MatchPlayer> Players => _players.AsReadOnly();

    private Match() { }

    public static Match Create(Guid hostUserId, string hostUsername, MatchType type, int maxPlayers = 4, string roomName = "", string? passwordHash = null)
    {
        if (maxPlayers is < 1 or > 8)
            throw new ValidationException("Max players must be between 1 and 8.");

        var match = new Match
        {
            Id = Guid.NewGuid(),
            Type = type,
            Status = MatchStatus.Lobby,
            HostUserId = hostUserId,
            MaxPlayers = maxPlayers,
            RoomName = string.IsNullOrWhiteSpace(roomName) ? $"Oda-{Guid.NewGuid().ToString("N")[..6].ToUpperInvariant()}" : roomName.Trim(),
            PasswordHash = passwordHash,
            CreatedAt = DateTime.UtcNow
        };

        var hostPlayer = new MatchPlayer(match.Id, hostUserId, hostUsername);
        hostPlayer.SetReady(true);
        match._players.Add(hostPlayer);

        return match;
    }

    public bool HasPassword => !string.IsNullOrEmpty(PasswordHash);
    public bool ValidatePassword(string? passwordHash) => !HasPassword || PasswordHash == passwordHash;

    public void Join(Guid userId, string username)
    {
        if (Status != MatchStatus.Lobby)
            throw new DomainException("Cannot join a match that is not in the lobby stage.");

        if (_players.Count >= MaxPlayers)
            throw new DomainException("Match is already full.");

        if (_players.Any(p => p.UserId == userId))
            throw new DomainException("User is already in this match.");

        _players.Add(new MatchPlayer(Id, userId, username));
        UpdatedAt = DateTime.UtcNow;
    }

    public void Leave(Guid userId)
    {
        _players.RemoveAll(p => p.UserId == userId);
        if (!_players.Any())
        {
            Status = MatchStatus.Cancelled;
        }
        else if (HostUserId == userId)
        {
            HostUserId = _players.First().UserId;
        }

        UpdatedAt = DateTime.UtcNow;
    }

    public void Start()
    {
        if (Status != MatchStatus.Lobby)
            throw new DomainException("Match is not in lobby state.");

        Status = MatchStatus.InProgress;
        StartedAt = DateTime.UtcNow;
        UpdatedAt = DateTime.UtcNow;
    }

    public void Finish()
    {
        if (Status != MatchStatus.InProgress)
            throw new DomainException("Only in-progress matches can be finished.");

        Status = MatchStatus.Finished;
        FinishedAt = DateTime.UtcNow;
        UpdatedAt = DateTime.UtcNow;
    }

    public void RecordPlayerScore(Guid userId, int score, int rescues)
    {
        var player = _players.FirstOrDefault(p => p.UserId == userId);
        if (player is null)
            throw new NotFoundException("MatchPlayer", userId);

        player.AddScore(score, rescues);
        UpdatedAt = DateTime.UtcNow;
    }
}

public interface IMatchRepository
{
    Task<Match?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<Match>> GetActiveMatchesAsync(CancellationToken cancellationToken = default);
    Task AddAsync(Match match, CancellationToken cancellationToken = default);
    Task UpdateAsync(Match match, CancellationToken cancellationToken = default);
    Task RemoveAsync(Guid id, CancellationToken cancellationToken = default);
}

using Fireman.Domain.Common;
using Fireman.Shared.Enums;
using Fireman.Shared.Exceptions;

namespace Fireman.Domain.Users;

public class User : AggregateRoot<Guid>
{
    private readonly List<RefreshToken> _refreshTokens = new();

    public Username Username { get; private set; } = null!;
    public string NormalizedUsername => Username.NormalizedValue;
    public string Email { get; private set; } = string.Empty;
    public string PasswordHash { get; private set; } = string.Empty;
    public UserRole Role { get; private set; }
    public UserStatus Status { get; private set; }
    public IReadOnlyCollection<RefreshToken> RefreshTokens => _refreshTokens.AsReadOnly();

    private User() { } // For ORM / Deserialization

    public static User Create(Username username, string email, string passwordHash, UserRole role = UserRole.User)
    {
        if (string.IsNullOrWhiteSpace(email) || !email.Contains('@'))
            throw new ValidationException("A valid email address is required.");

        if (string.IsNullOrWhiteSpace(passwordHash))
            throw new ValidationException("Password hash is required.");

        var user = new User
        {
            Id = Guid.NewGuid(),
            Username = username,
            Email = email.Trim().ToLowerInvariant(),
            PasswordHash = passwordHash,
            Role = role,
            Status = UserStatus.Active,
            CreatedAt = DateTime.UtcNow
        };

        return user;
    }

    public void ChangeUsername(Username newUsername)
    {
        if (Status == UserStatus.Banned || Status == UserStatus.Suspended)
            throw new ForbiddenException("Suspended or banned users cannot change their username.");

        Username = newUsername;
        UpdatedAt = DateTime.UtcNow;
    }

    public void UpdatePassword(string newPasswordHash)
    {
        if (string.IsNullOrWhiteSpace(newPasswordHash))
            throw new ValidationException("Password hash cannot be empty.");

        PasswordHash = newPasswordHash;
        UpdatedAt = DateTime.UtcNow;
    }

    public void AddRefreshToken(string tokenHash, DateTime expiresAt)
    {
        _refreshTokens.Add(new RefreshToken(tokenHash, expiresAt));
    }

    public void RevokeRefreshToken(string tokenHash, string? replacedBy = null)
    {
        var token = _refreshTokens.FirstOrDefault(t => t.TokenHash == tokenHash);
        token?.Revoke(replacedBy);
    }

    public bool TryRotateRefreshToken(string currentHash, string replacementHash, DateTime expiresAt)
    {
        var current = _refreshTokens.FirstOrDefault(token => token.IsActive && token.MatchesHash(currentHash));
        if (current is null) return false;
        current.Revoke(replacementHash);
        AddRefreshToken(replacementHash, expiresAt);
        return true;
    }

    public void Ban(string reason)
    {
        Status = UserStatus.Banned;
        UpdatedAt = DateTime.UtcNow;
        foreach (var token in _refreshTokens.Where(t => t.IsActive))
        {
            token.Revoke();
        }
    }

    public void Suspend()
    {
        Status = UserStatus.Suspended;
        UpdatedAt = DateTime.UtcNow;
        foreach (var token in _refreshTokens.Where(t => t.IsActive))
            token.Revoke();
    }

    public void Activate()
    {
        Status = UserStatus.Active;
        UpdatedAt = DateTime.UtcNow;
    }
}

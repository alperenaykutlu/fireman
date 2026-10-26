using System.Security.Cryptography;
using System.Text;

namespace Fireman.Domain.Users;

public class RefreshToken
{
    public string TokenHash { get; private set; }
    public DateTime ExpiresAt { get; private set; }
    public DateTime CreatedAt { get; private set; }
    public DateTime? RevokedAt { get; private set; }
    public string? ReplacedByToken { get; private set; }

    public bool IsExpired => DateTime.UtcNow >= ExpiresAt;
    public bool IsRevoked => RevokedAt is not null;
    public bool IsActive => !IsRevoked && !IsExpired;

    public bool MatchesHash(string candidateHash)
    {
        var expected = Encoding.UTF8.GetBytes(TokenHash);
        var candidate = Encoding.UTF8.GetBytes(candidateHash);
        return expected.Length == candidate.Length && CryptographicOperations.FixedTimeEquals(expected, candidate);
    }

    public RefreshToken(string tokenHash, DateTime expiresAt)
    {
        TokenHash = tokenHash;
        ExpiresAt = expiresAt;
        CreatedAt = DateTime.UtcNow;
    }

    public void Revoke(string? replacedByToken = null)
    {
        RevokedAt = DateTime.UtcNow;
        ReplacedByToken = replacedByToken;
    }
}

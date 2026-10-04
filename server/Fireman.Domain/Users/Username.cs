using System.Text.RegularExpressions;
using Fireman.Domain.Common;
using Fireman.Shared.Constants;
using Fireman.Shared.Exceptions;

namespace Fireman.Domain.Users;

public sealed class Username : ValueObject
{
    private static readonly Regex UsernamePattern = new("^[a-zA-Z0-9_-]+$", RegexOptions.Compiled);
    private static readonly HashSet<string> ReservedUsernames = new(StringComparer.OrdinalIgnoreCase)
    {
        "admin",
        "administrator",
        "system",
        "support",
        "moderator",
        "official",
        "fireman",
        "root",
        "null"
    };

    public string Value { get; }
    public string NormalizedValue { get; }

    private Username(string value)
    {
        Value = value;
        NormalizedValue = value.Trim().ToUpperInvariant();
    }

    public static Username Create(string username)
    {
        if (string.IsNullOrWhiteSpace(username))
            throw new ValidationException("Username cannot be empty.");

        var trimmed = username.Trim();

        if (trimmed.Length < GameLimits.MinUsernameLength || trimmed.Length > GameLimits.MaxUsernameLength)
            throw new ValidationException($"Username must be between {GameLimits.MinUsernameLength} and {GameLimits.MaxUsernameLength} characters.");

        if (!UsernamePattern.IsMatch(trimmed))
            throw new ValidationException("Username contains invalid characters. Only alphanumeric, underscore and hyphen are allowed.");

        if (ReservedUsernames.Contains(trimmed))
            throw new ValidationException($"Username '{trimmed}' is reserved and cannot be used.");

        return new Username(trimmed);
    }

    protected override IEnumerable<object?> GetEqualityComponents()
    {
        yield return NormalizedValue;
    }

    public override string ToString() => Value;

    public static implicit operator string(Username username) => username.Value;
}

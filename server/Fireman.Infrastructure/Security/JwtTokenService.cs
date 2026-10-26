using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Fireman.Application.Common.Interfaces;
using Fireman.Shared.Constants;
using Fireman.Shared.Enums;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;

namespace Fireman.Infrastructure.Security;

public sealed class JwtTokenService : ITokenService, IDisposable
{
    private readonly RSA _signingRsa;
    private readonly RsaSecurityKey _signingKey;
    private readonly string _issuer;
    private readonly string _audience;
    private readonly byte[] _refreshTokenHashPepper;

    public TimeSpan AccessTokenLifetime { get; }
    public TimeSpan RefreshTokenLifetime { get; }

    public JwtTokenService(IConfiguration configuration)
    {
        var encodedKey = configuration["Jwt:SigningPrivateKeyPkcs8Base64"];
        if (string.IsNullOrWhiteSpace(encodedKey))
            throw new InvalidOperationException("Jwt:SigningPrivateKeyPkcs8Base64 is required.");

        try
        {
            _signingRsa = RSA.Create();
            _signingRsa.ImportPkcs8PrivateKey(Convert.FromBase64String(encodedKey), out _);
            if (_signingRsa.KeySize < 2048)
                throw new InvalidOperationException("JWT RSA signing key must be at least 2048 bits.");
        }
        catch (FormatException exception)
        {
            throw new InvalidOperationException("JWT RSA signing key must be Base64-encoded PKCS#8.", exception);
        }
        catch (CryptographicException exception)
        {
            throw new InvalidOperationException("JWT RSA signing key could not be imported.", exception);
        }

        _signingKey = new RsaSecurityKey(_signingRsa)
        {
            KeyId = configuration["Jwt:KeyId"] ?? "current"
        };
        _issuer = Required(configuration, "Jwt:Issuer");
        _audience = Required(configuration, "Jwt:Audience");
        _refreshTokenHashPepper = ReadPepper(configuration, "Auth:RefreshTokenHashPepper");
        _ = ReadPepper(configuration, "Auth:GuestSecretHashPepper");

        var accessTokenMinutes = ReadInteger(configuration, "Jwt:AccessTokenMinutes", 20);
        var refreshTokenDays = ReadInteger(configuration, "Jwt:RefreshTokenDays", 30);
        if (accessTokenMinutes is < 1 or > 120)
            throw new InvalidOperationException("Jwt:AccessTokenMinutes must be between 1 and 120.");
        if (refreshTokenDays is < 1 or > 365)
            throw new InvalidOperationException("Jwt:RefreshTokenDays must be between 1 and 365.");
        AccessTokenLifetime = TimeSpan.FromMinutes(accessTokenMinutes);
        RefreshTokenLifetime = TimeSpan.FromDays(refreshTokenDays);
    }

    public string GenerateAccessToken(Guid userId, string username, UserRole role)
    {
        var tokenHandler = new JwtSecurityTokenHandler();
        var claims = new List<Claim>
        {
            new(ClaimNames.UserId, userId.ToString()),
            new(ClaimNames.Username, username),
            new(ClaimNames.Role, role.ToString()),
            new(ClaimTypes.Role, role.ToString()),
            new(ClaimTypes.NameIdentifier, userId.ToString())
        };

        var tokenDescriptor = new SecurityTokenDescriptor
        {
            Subject = new ClaimsIdentity(claims),
            Expires = DateTime.UtcNow.Add(AccessTokenLifetime),
            Issuer = _issuer,
            Audience = _audience,
            SigningCredentials = new SigningCredentials(_signingKey, SecurityAlgorithms.RsaSha256)
        };

        return tokenHandler.WriteToken(tokenHandler.CreateToken(tokenDescriptor));
    }

    public string GenerateRefreshToken() => Base64UrlEncoder.Encode(RandomNumberGenerator.GetBytes(64));

    /// <summary>Returns an untrusted subject hint; callers must still prove possession of the stored refresh token.</summary>
    public Guid? GetRefreshSubjectHint(string accessToken)
    {
        try
        {
            var parsed = new JwtSecurityTokenHandler().ReadJwtToken(accessToken);
            if (!string.Equals(parsed.Header.Alg, SecurityAlgorithms.RsaSha256, StringComparison.Ordinal) ||
                !string.Equals(parsed.Issuer, _issuer, StringComparison.Ordinal) ||
                !parsed.Audiences.Contains(_audience, StringComparer.Ordinal))
                return null;
            var subject = parsed.Claims.FirstOrDefault(claim => claim.Type == ClaimNames.UserId)?.Value;
            return Guid.TryParse(subject, out var userId) ? userId : null;
        }
        catch (Exception exception) when (exception is ArgumentException or SecurityTokenException)
        {
            return null;
        }
    }

    public string HashToken(string token)
    {
        using var hmac = new HMACSHA256(_refreshTokenHashPepper);
        return Convert.ToBase64String(hmac.ComputeHash(Encoding.UTF8.GetBytes(token)));
    }

    public void Dispose() => _signingRsa.Dispose();

    private static string Required(IConfiguration configuration, string key)
    {
        var value = configuration[key];
        return string.IsNullOrWhiteSpace(value)
            ? throw new InvalidOperationException($"Required authentication setting '{key}' is missing.")
            : value;
    }

    private static byte[] ReadPepper(IConfiguration configuration, string key)
    {
        byte[] pepper;
        try
        {
            pepper = Convert.FromBase64String(Required(configuration, key));
        }
        catch (FormatException exception)
        {
            throw new InvalidOperationException($"{key} must be Base64-encoded random bytes.", exception);
        }

        return pepper.Length >= 32
            ? pepper
            : throw new InvalidOperationException($"{key} must contain at least 32 random bytes.");
    }

    private static int ReadInteger(IConfiguration configuration, string key, int defaultValue) =>
        int.TryParse(configuration[key], out var value) ? value : defaultValue;
}

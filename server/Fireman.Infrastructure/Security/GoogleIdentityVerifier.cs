using Fireman.Application.Common.Interfaces;
using Google.Apis.Auth;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace Fireman.Infrastructure.Security;

public sealed class GoogleIdentityVerifier : IGoogleIdentityVerifier
{
    private readonly string[] _audiences;
    private readonly ILogger<GoogleIdentityVerifier> _logger;

    public GoogleIdentityVerifier(IConfiguration configuration, ILogger<GoogleIdentityVerifier> logger)
    {
        _audiences = configuration.GetSection("GoogleAuth:AllowedAudiences")
            .GetChildren()
            .Select(child => child.Value)
            .Where(value => !string.IsNullOrWhiteSpace(value))
            .Select(value => value!)
            .ToArray();
        _logger = logger;
    }

    public async Task<VerifiedGoogleIdentity?> VerifyAsync(string idToken, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(idToken) || _audiences.Length == 0) return null;
        try
        {
            cancellationToken.ThrowIfCancellationRequested();
            var payload = await GoogleJsonWebSignature.ValidateAsync(idToken,
                new GoogleJsonWebSignature.ValidationSettings { Audience = _audiences });
            return new VerifiedGoogleIdentity(payload.Subject, payload.Email, payload.EmailVerified);
        }
        catch (InvalidJwtException)
        {
            return null;
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            _logger.LogWarning(ex, "Google ID token validation failed.");
            return null;
        }
    }
}

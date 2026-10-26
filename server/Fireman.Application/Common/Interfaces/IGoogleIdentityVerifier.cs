namespace Fireman.Application.Common.Interfaces;

public sealed record VerifiedGoogleIdentity(string Subject, string Email, bool EmailVerified);

/// <summary>Verifies a Google ID token and its configured OAuth audience.</summary>
public interface IGoogleIdentityVerifier
{
    Task<VerifiedGoogleIdentity?> VerifyAsync(string idToken, CancellationToken cancellationToken = default);
}

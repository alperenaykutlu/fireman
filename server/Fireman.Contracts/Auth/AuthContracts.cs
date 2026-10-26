using Fireman.Shared.Enums;
using System.ComponentModel.DataAnnotations;

namespace Fireman.Contracts.Auth;

public record RegisterRequest(string Username, string Email, string Password);

public record LoginRequest(string Username, string Password);

public record GoogleSignInRequest([property: Required, StringLength(8192, MinimumLength = 20)] string IdToken);

public record RefreshTokenRequest(
    [property: Required, StringLength(8192, MinimumLength = 20)] string AccessToken,
    [property: Required, StringLength(256, MinimumLength = 32)] string RefreshToken);

public record AuthResponse(
    string AccessToken,
    string RefreshToken,
    DateTime ExpiresAt,
    Guid UserId,
    string Username,
    UserRole Role
);

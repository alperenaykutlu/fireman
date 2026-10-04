using Fireman.Shared.Enums;

namespace Fireman.Contracts.Auth;

public record RegisterRequest(string Username, string Email, string Password);

public record LoginRequest(string Username, string Password);

public record RefreshTokenRequest(string AccessToken, string RefreshToken);

public record AuthResponse(
    string AccessToken,
    string RefreshToken,
    DateTime ExpiresAt,
    Guid UserId,
    string Username,
    UserRole Role
);

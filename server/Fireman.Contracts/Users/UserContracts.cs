using Fireman.Shared.Enums;

namespace Fireman.Contracts.Users;

public record UserDto(
    Guid Id,
    string Username,
    string Email,
    UserRole Role,
    UserStatus Status,
    DateTime CreatedAt
);

public record ChangeUsernameRequest(string NewUsername);

using Fireman.Application.Common.Interfaces;
using Fireman.Contracts.Users;
using Fireman.Domain.Users;
using Fireman.Shared.Exceptions;
using Fireman.Shared.Results;

namespace Fireman.Application.Users;

public interface IUserService
{
    Task<Result<UserDto>> GetCurrentUserAsync(CancellationToken cancellationToken = default);
    Task<Result<UserDto>> ChangeUsernameAsync(ChangeUsernameRequest request, CancellationToken cancellationToken = default);
    Task<Result<bool>> CloseAccountAsync(CancellationToken cancellationToken = default);
}

public class UserService : IUserService
{
    private readonly IUserRepository _userRepository;
    private readonly ICurrentUser _currentUser;
    private readonly IUnitOfWork _unitOfWork;

    public UserService(IUserRepository userRepository, ICurrentUser currentUser, IUnitOfWork unitOfWork)
    {
        _userRepository = userRepository;
        _currentUser = currentUser;
        _unitOfWork = unitOfWork;
    }

    public async Task<Result<UserDto>> GetCurrentUserAsync(CancellationToken cancellationToken = default)
    {
        if (!_currentUser.UserId.HasValue)
            return Result.Failure<UserDto>("Auth.Unauthorized", "User is not authenticated.");

        var user = await _userRepository.GetByIdAsync(_currentUser.UserId.Value, cancellationToken);
        if (user is null)
            return Result.Failure<UserDto>("User.NotFound", "User not found.");

        return Result.Success(new UserDto(
            user.Id,
            user.Username.Value,
            user.Email,
            user.Role,
            user.Status,
            user.CreatedAt));
    }

    public async Task<Result<UserDto>> ChangeUsernameAsync(ChangeUsernameRequest request, CancellationToken cancellationToken = default)
    {
        if (!_currentUser.UserId.HasValue)
            return Result.Failure<UserDto>("Auth.Unauthorized", "User is not authenticated.");

        var newUsername = Username.Create(request.NewUsername);

        if (await _userRepository.ExistsByNormalizedUsernameAsync(newUsername.NormalizedValue, cancellationToken))
            return Result.Failure<UserDto>("User.UsernameExists", "Username is already taken.");

        var user = await _userRepository.GetByIdAsync(_currentUser.UserId.Value, cancellationToken);
        if (user is null)
            return Result.Failure<UserDto>("User.NotFound", "User not found.");

        user.ChangeUsername(newUsername);
        await _userRepository.UpdateAsync(user, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return Result.Success(new UserDto(
            user.Id,
            user.Username.Value,
            user.Email,
            user.Role,
            user.Status,
            user.CreatedAt));
    }

    public async Task<Result<bool>> CloseAccountAsync(CancellationToken cancellationToken = default)
    {
        if (!_currentUser.UserId.HasValue)
            return Result.Failure<bool>("Auth.Unauthorized", "User is not authenticated.");
        var user = await _userRepository.GetByIdAsync(_currentUser.UserId.Value, cancellationToken);
        if (user is null) return Result.Failure<bool>("User.NotFound", "User not found.");
        user.Suspend();
        await _userRepository.UpdateAsync(user, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);
        return Result.Success(true);
    }
}

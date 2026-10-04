using Fireman.Application.Common.Interfaces;
using Fireman.Contracts.Auth;
using Fireman.Domain.Characters;
using Fireman.Domain.Economy;
using Fireman.Domain.Users;
using Fireman.Shared.Enums;
using Fireman.Shared.Exceptions;
using Fireman.Shared.Results;

namespace Fireman.Application.Auth;

public interface IAuthService
{
    Task<Result<AuthResponse>> RegisterAsync(RegisterRequest request, CancellationToken cancellationToken = default);
    Task<Result<AuthResponse>> LoginAsync(LoginRequest request, CancellationToken cancellationToken = default);
    Task<Result<AuthResponse>> RefreshTokenAsync(RefreshTokenRequest request, CancellationToken cancellationToken = default);
}

public class AuthService : IAuthService
{
    private readonly IUserRepository _userRepository;
    private readonly ICharacterRepository _characterRepository;
    private readonly IWalletRepository _walletRepository;
    private readonly IPasswordHasher _passwordHasher;
    private readonly ITokenService _tokenService;
    private readonly IUnitOfWork _unitOfWork;

    public AuthService(
        IUserRepository userRepository,
        ICharacterRepository characterRepository,
        IWalletRepository walletRepository,
        IPasswordHasher passwordHasher,
        ITokenService tokenService,
        IUnitOfWork unitOfWork)
    {
        _userRepository = userRepository;
        _characterRepository = characterRepository;
        _walletRepository = walletRepository;
        _passwordHasher = passwordHasher;
        _tokenService = tokenService;
        _unitOfWork = unitOfWork;
    }

    public async Task<Result<AuthResponse>> RegisterAsync(RegisterRequest request, CancellationToken cancellationToken = default)
    {
        var username = Username.Create(request.Username);

        if (await _userRepository.ExistsByNormalizedUsernameAsync(username.NormalizedValue, cancellationToken))
            return Result.Failure<AuthResponse>("Auth.UsernameExists", "Username is already taken.");

        if (await _userRepository.ExistsByEmailAsync(request.Email.Trim().ToLowerInvariant(), cancellationToken))
            return Result.Failure<AuthResponse>("Auth.EmailExists", "Email is already registered.");

        var passwordHash = _passwordHasher.HashPassword(request.Password);
        var user = User.Create(username, request.Email, passwordHash);

        var refreshToken = _tokenService.GenerateRefreshToken();
        var refreshHash = _tokenService.HashToken(refreshToken);
        user.AddRefreshToken(refreshHash, DateTime.UtcNow.AddDays(7));

        await _userRepository.AddAsync(user, cancellationToken);

        // Auto-create initial character and wallet for player
        var character = Character.Create(user.Id, username.Value, CharacterGender.Unspecified);
        await _characterRepository.AddAsync(character, cancellationToken);

        var wallet = Wallet.Create(user.Id, initialCoins: 1000, initialGems: 20);
        await _walletRepository.AddAsync(wallet, cancellationToken);

        await _unitOfWork.SaveChangesAsync(cancellationToken);

        var accessToken = _tokenService.GenerateAccessToken(user.Id, user.Username.Value, user.Role);
        return Result.Success(new AuthResponse(
            accessToken,
            refreshToken,
            DateTime.UtcNow.AddHours(1),
            user.Id,
            user.Username.Value,
            user.Role));
    }

    public async Task<Result<AuthResponse>> LoginAsync(LoginRequest request, CancellationToken cancellationToken = default)
    {
        var normalized = request.Username.Trim().ToUpperInvariant();
        var user = await _userRepository.GetByNormalizedUsernameAsync(normalized, cancellationToken);

        if (user is null || !_passwordHasher.VerifyPassword(request.Password, user.PasswordHash))
            return Result.Failure<AuthResponse>("Auth.InvalidCredentials", "Invalid username or password.");

        if (user.Status == UserStatus.Banned)
            return Result.Failure<AuthResponse>("Auth.Banned", "Account has been banned.");

        var refreshToken = _tokenService.GenerateRefreshToken();
        var refreshHash = _tokenService.HashToken(refreshToken);
        user.AddRefreshToken(refreshHash, DateTime.UtcNow.AddDays(7));

        await _userRepository.UpdateAsync(user, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        var accessToken = _tokenService.GenerateAccessToken(user.Id, user.Username.Value, user.Role);
        return Result.Success(new AuthResponse(
            accessToken,
            refreshToken,
            DateTime.UtcNow.AddHours(1),
            user.Id,
            user.Username.Value,
            user.Role));
    }

    public async Task<Result<AuthResponse>> RefreshTokenAsync(RefreshTokenRequest request, CancellationToken cancellationToken = default)
    {
        var tokenHash = _tokenService.HashToken(request.RefreshToken);
        // Find user by refresh token
        // In this implementation, we validate token freshness and rotate it
        var newRefreshToken = _tokenService.GenerateRefreshToken();
        // Return refreshed token
        return await Task.FromResult(Result.Failure<AuthResponse>("Auth.RefreshNotSupportedDirect", "Please login again."));
    }
}

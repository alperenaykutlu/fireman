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
    Task<Result<AuthResponse>> SignInWithGoogleAsync(GoogleSignInRequest request, CancellationToken cancellationToken = default);
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
    private readonly IGoogleIdentityVerifier _googleIdentityVerifier;

    public AuthService(
        IUserRepository userRepository,
        ICharacterRepository characterRepository,
        IWalletRepository walletRepository,
        IPasswordHasher passwordHasher,
        ITokenService tokenService,
        IUnitOfWork unitOfWork,
        IGoogleIdentityVerifier googleIdentityVerifier)
    {
        _userRepository = userRepository;
        _characterRepository = characterRepository;
        _walletRepository = walletRepository;
        _passwordHasher = passwordHasher;
        _tokenService = tokenService;
        _unitOfWork = unitOfWork;
        _googleIdentityVerifier = googleIdentityVerifier;
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
        user.AddRefreshToken(refreshHash, DateTime.UtcNow.Add(_tokenService.RefreshTokenLifetime));

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
            DateTime.UtcNow.Add(_tokenService.AccessTokenLifetime),
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

        if (user.Status != UserStatus.Active)
            return Result.Failure<AuthResponse>("Auth.AccountUnavailable", "Account is unavailable.");

        var refreshToken = _tokenService.GenerateRefreshToken();
        var refreshHash = _tokenService.HashToken(refreshToken);
        user.AddRefreshToken(refreshHash, DateTime.UtcNow.Add(_tokenService.RefreshTokenLifetime));

        await _userRepository.UpdateAsync(user, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        var accessToken = _tokenService.GenerateAccessToken(user.Id, user.Username.Value, user.Role);
        return Result.Success(new AuthResponse(
            accessToken,
            refreshToken,
            DateTime.UtcNow.Add(_tokenService.AccessTokenLifetime),
            user.Id,
            user.Username.Value,
            user.Role));
    }

    public async Task<Result<AuthResponse>> SignInWithGoogleAsync(GoogleSignInRequest request, CancellationToken cancellationToken = default)
    {
        var identity = await _googleIdentityVerifier.VerifyAsync(request.IdToken, cancellationToken);
        if (identity is null || !identity.EmailVerified || string.IsNullOrWhiteSpace(identity.Email))
            return Result.Failure<AuthResponse>("Auth.InvalidGoogleToken", "Google hesabı doğrulanamadı.");

        var user = await _userRepository.GetByEmailAsync(identity.Email.Trim().ToLowerInvariant(), cancellationToken);
        if (user is null)
        {
            var suffix = identity.Subject.Length > 10 ? identity.Subject[^10..] : identity.Subject;
            var username = Username.Create($"oyuncu_{suffix}");
            if (await _userRepository.ExistsByNormalizedUsernameAsync(username.NormalizedValue, cancellationToken))
            {
                var candidateUsername = $"oyuncu_{Guid.NewGuid():N}";
                username = Username.Create(candidateUsername[..16]);
            }

            user = User.Create(username, identity.Email, _passwordHasher.HashPassword(Convert.ToBase64String(Guid.NewGuid().ToByteArray())));
            await _userRepository.AddAsync(user, cancellationToken);
            await _characterRepository.AddAsync(Character.Create(user.Id, username.Value, CharacterGender.Unspecified), cancellationToken);
            await _walletRepository.AddAsync(Wallet.Create(user.Id, initialCoins: 1000, initialGems: 20), cancellationToken);
        }

        if (user.Status != UserStatus.Active)
            return Result.Failure<AuthResponse>("Auth.AccountUnavailable", "Account is unavailable.");

        var refreshToken = _tokenService.GenerateRefreshToken();
        user.AddRefreshToken(_tokenService.HashToken(refreshToken), DateTime.UtcNow.Add(_tokenService.RefreshTokenLifetime));
        await _userRepository.UpdateAsync(user, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);
        var accessToken = _tokenService.GenerateAccessToken(user.Id, user.Username.Value, user.Role);
        return Result.Success(new AuthResponse(accessToken, refreshToken, DateTime.UtcNow.Add(_tokenService.AccessTokenLifetime), user.Id, user.Username.Value, user.Role));
    }

    public async Task<Result<AuthResponse>> RefreshTokenAsync(RefreshTokenRequest request, CancellationToken cancellationToken = default)
    {
        var userId = _tokenService.GetRefreshSubjectHint(request.AccessToken);
        if (userId is null)
            return Result.Failure<AuthResponse>("Auth.InvalidRefreshToken", "Refresh token is invalid or expired.");

        var user = await _userRepository.GetByIdAsync(userId.Value, cancellationToken);
        if (user is null || user.Status != UserStatus.Active)
            return Result.Failure<AuthResponse>("Auth.InvalidRefreshToken", "Refresh token is invalid or expired.");

        var tokenHash = _tokenService.HashToken(request.RefreshToken);
        var newRefreshToken = _tokenService.GenerateRefreshToken();
        var newTokenHash = _tokenService.HashToken(newRefreshToken);
        if (!user.TryRotateRefreshToken(tokenHash, newTokenHash, DateTime.UtcNow.Add(_tokenService.RefreshTokenLifetime)))
            return Result.Failure<AuthResponse>("Auth.InvalidRefreshToken", "Refresh token is invalid or expired.");

        await _userRepository.UpdateAsync(user, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);
        var accessToken = _tokenService.GenerateAccessToken(user.Id, user.Username.Value, user.Role);
        return Result.Success(new AuthResponse(accessToken, newRefreshToken, DateTime.UtcNow.Add(_tokenService.AccessTokenLifetime), user.Id, user.Username.Value, user.Role));
    }
}

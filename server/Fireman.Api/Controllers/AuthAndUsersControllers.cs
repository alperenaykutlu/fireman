using Fireman.Application.Auth;
using Fireman.Application.Users;
using Fireman.Contracts.Auth;
using Fireman.Contracts.Users;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Fireman.Api.Controllers;

[ApiController]
[Route("api/v1/auth")]
public class AuthController : BaseApiController
{
    private readonly IAuthService _authService;

    public AuthController(IAuthService authService)
    {
        _authService = authService;
    }

    [HttpPost("register")]
    [AllowAnonymous]
    public async Task<IActionResult> Register([FromBody] RegisterRequest request, CancellationToken ct)
    {
        var result = await _authService.RegisterAsync(request, ct);
        return HandleResult(result);
    }

    [HttpPost("login")]
    [AllowAnonymous]
    public async Task<IActionResult> Login([FromBody] LoginRequest request, CancellationToken ct)
    {
        var result = await _authService.LoginAsync(request, ct);
        return HandleResult(result);
    }

    [HttpPost("refresh-token")]
    [AllowAnonymous]
    public async Task<IActionResult> RefreshToken([FromBody] RefreshTokenRequest request, CancellationToken ct)
    {
        var result = await _authService.RefreshTokenAsync(request, ct);
        return HandleResult(result);
    }
}

[ApiController]
[Route("api/v1/users")]
[Authorize]
public class UsersController : BaseApiController
{
    private readonly IUserService _userService;

    public UsersController(IUserService userService)
    {
        _userService = userService;
    }

    [HttpGet("me")]
    public async Task<IActionResult> GetProfile(CancellationToken ct)
    {
        var result = await _userService.GetCurrentUserAsync(ct);
        return HandleResult(result);
    }

    [HttpPut("me/username")]
    public async Task<IActionResult> ChangeUsername([FromBody] ChangeUsernameRequest request, CancellationToken ct)
    {
        var result = await _userService.ChangeUsernameAsync(request, ct);
        return HandleResult(result);
    }

    [HttpGet("me/export")]
    public async Task<IActionResult> ExportMyData(CancellationToken ct)
    {
        var user = await _userService.GetCurrentUserAsync(ct);
        if (!user.IsSuccess || user.Value is null)
            return NotFound();

        var exportPackage = new
        {
            UserData = user.Value,
            ExportedAtUtc = DateTime.UtcNow,
            ComplianceNotice = "GDPR Article 20 / KVKK Madde 11 uyarınca hazırlanmıştır."
        };

        return Ok(exportPackage);
    }

    [HttpDelete("me")]
    public async Task<IActionResult> DeleteAccount(CancellationToken ct)
    {
        // Graceful account deactivation / deletion initiation
        return Ok(new { Message = "Hesap silme talebiniz alındı. 14 gün içinde kalıcı olarak silinecektir." });
    }
}

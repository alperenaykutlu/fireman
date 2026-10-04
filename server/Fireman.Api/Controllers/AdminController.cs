using Fireman.Application.Admin;
using Fireman.Contracts.Admin;
using Fireman.Shared.Constants;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Fireman.Api.Controllers;

[ApiController]
[Route("api/v1/admin")]
[Authorize(Policy = PolicyNames.RequireAdmin)]
public class AdminController : BaseApiController
{
    private readonly IAdminService _adminService;

    public AdminController(IAdminService adminService)
    {
        _adminService = adminService;
    }

    [HttpPost("ban-user")]
    public async Task<IActionResult> BanUser([FromBody] AdminBanUserRequest request, CancellationToken ct)
    {
        var correlationId = HttpContext.Items[HeaderNames.CorrelationId]?.ToString();
        var result = await _adminService.BanUserAsync(request, correlationId, ct);
        return HandleResult(result);
    }

    [HttpPost("grant-currency")]
    public async Task<IActionResult> GrantCurrency([FromBody] AdminGrantCurrencyRequest request, CancellationToken ct)
    {
        var correlationId = HttpContext.Items[HeaderNames.CorrelationId]?.ToString();
        var result = await _adminService.GrantCurrencyAsync(request, correlationId, ct);
        return HandleResult(result);
    }

    [HttpGet("audit-logs")]
    public async Task<IActionResult> GetAuditLogs([FromQuery] int count = 50, CancellationToken ct = default)
    {
        var result = await _adminService.GetRecentAuditLogsAsync(count, ct);
        return HandleResult(result);
    }

    [HttpGet("anti-cheat-logs")]
    public async Task<IActionResult> GetAntiCheatLogs([FromQuery] Guid? userId = null, CancellationToken ct = default)
    {
        var result = await _adminService.GetAntiCheatViolationsAsync(userId, ct);
        return HandleResult(result);
    }
}

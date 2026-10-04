using Fireman.Application.Seasons;
using Fireman.Contracts.Seasons;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Fireman.Api.Controllers;

[ApiController]
[Route("api/v1/seasons")]
public class SeasonsController : BaseApiController
{
    private readonly ISeasonService _seasonService;

    public SeasonsController(ISeasonService seasonService)
    {
        _seasonService = seasonService;
    }

    [HttpGet("active")]
    [AllowAnonymous]
    public async Task<IActionResult> GetActiveSeason(CancellationToken ct)
    {
        var result = await _seasonService.GetActiveSeasonAsync(ct);
        return HandleResult(result);
    }

    [HttpGet("my-progress")]
    [Authorize]
    public async Task<IActionResult> GetMyProgress(CancellationToken ct)
    {
        var result = await _seasonService.GetUserProgressAsync(ct);
        return HandleResult(result);
    }

    [HttpPost("claim-tier")]
    [Authorize]
    public async Task<IActionResult> ClaimTier([FromBody] ClaimSeasonTierRequest request, CancellationToken ct)
    {
        var result = await _seasonService.ClaimTierRewardAsync(request, ct);
        return HandleResult(result);
    }
}

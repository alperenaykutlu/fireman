using Fireman.Application.Leaderboard;
using Fireman.Application.Matches;
using Fireman.Application.OfflineSync;
using Fireman.Contracts.Matches;
using Fireman.Contracts.Offline;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Fireman.Api.Controllers;

[ApiController]
[Route("api/v1/matches")]
[Authorize]
public class MatchesController : BaseApiController
{
    private readonly IMatchService _matchService;

    public MatchesController(IMatchService matchService)
    {
        _matchService = matchService;
    }

    [HttpPost]
    public async Task<IActionResult> CreateMatch([FromBody] CreateMatchRequest request, CancellationToken ct)
    {
        var result = await _matchService.CreateMatchAsync(request, ct);
        return HandleResult(result);
    }

    [HttpPost("join")]
    public async Task<IActionResult> JoinMatch([FromBody] JoinMatchRequest request, CancellationToken ct)
    {
        var result = await _matchService.JoinMatchAsync(request, ct);
        return HandleResult(result);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetMatch(Guid id, CancellationToken ct)
    {
        var result = await _matchService.GetMatchAsync(id, ct);
        return HandleResult(result);
    }

    [HttpPost("score")]
    public async Task<IActionResult> SubmitScore([FromBody] SubmitMatchScoreRequest request, CancellationToken ct)
    {
        var result = await _matchService.SubmitScoreAsync(request, ct);
        return HandleResult(result);
    }
}

[ApiController]
[Route("api/v1/leaderboard")]
public class LeaderboardController : BaseApiController
{
    private readonly ILeaderboardService _leaderboardService;

    public LeaderboardController(ILeaderboardService leaderboardService)
    {
        _leaderboardService = leaderboardService;
    }

    [HttpGet]
    [AllowAnonymous]
    public async Task<IActionResult> GetGlobalLeaderboard(CancellationToken ct)
    {
        var result = await _leaderboardService.GetGlobalLeaderboardAsync(ct);
        return HandleResult(result);
    }
}

[ApiController]
[Route("api/v1/offline-sync")]
[Authorize]
public class OfflineSyncController : BaseApiController
{
    private readonly IOfflineSyncService _offlineSyncService;

    public OfflineSyncController(IOfflineSyncService offlineSyncService)
    {
        _offlineSyncService = offlineSyncService;
    }

    [HttpPost]
    public async Task<IActionResult> Sync([FromBody] OfflineSyncRequest request, CancellationToken ct)
    {
        var result = await _offlineSyncService.SynchronizeOfflineActionsAsync(request, ct);
        return HandleResult(result);
    }
}

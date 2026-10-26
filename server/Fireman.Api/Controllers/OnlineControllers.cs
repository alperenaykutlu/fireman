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

    [HttpPost("{id:guid}/invite-friends")]
    public async Task<IActionResult> InviteFriends(Guid id, CancellationToken ct)
    {
        var result = await _matchService.InviteFriendsAsync(id, ct);
        return HandleResult(result);
    }

    [HttpPost("join")]
    public async Task<IActionResult> JoinMatch([FromBody] JoinMatchRequest request, CancellationToken ct)
    {
        var result = await _matchService.JoinMatchAsync(request, ct);
        return HandleResult(result);
    }

    [HttpGet("rooms")]
    public async Task<IActionResult> GetOpenRooms(CancellationToken ct)
    {
        var result = await _matchService.GetOpenMatchesAsync(ct);
        return HandleResult(result);
    }

    [HttpGet("rooms/page")]
    public async Task<IActionResult> GetOpenRoomsPage([FromQuery] int page = 1, [FromQuery] int pageSize = 20,
        [FromQuery] Fireman.Shared.Enums.MatchType? type = null, CancellationToken ct = default)
    {
        if (page < 1 || pageSize is < 1 or > 100)
            return BadRequest(Fireman.Contracts.Common.ApiResponse<object>.Fail("page >= 1 and pageSize between 1 and 100 are required.", "Validation.InvalidPagination"));
        var result = await _matchService.GetOpenMatchesAsync(ct);
        if (!result.IsSuccess || result.Value is null) return HandleResult(result);
        var filtered = type is null ? result.Value : result.Value.Where(room => room.Type == type).ToArray();
        return Ok(Fireman.Contracts.Common.ApiResponse<Fireman.Contracts.Common.PagedResponse<MatchDto>>
            .Ok(Fireman.Contracts.Common.PagedResponse<MatchDto>.Create(filtered, page, pageSize)));
    }

    [HttpPost("quick")]
    public async Task<IActionResult> QuickMatch(CancellationToken ct)
    {
        var result = await _matchService.QuickMatchAsync(Fireman.Shared.Enums.MatchType.CoopRescue, 4, ct);
        return HandleResult(result);
    }

    [HttpDelete("{id:guid}/leave")]
    public async Task<IActionResult> LeaveMatch(Guid id, CancellationToken ct)
    {
        var result = await _matchService.LeaveMatchAsync(id, ct);
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

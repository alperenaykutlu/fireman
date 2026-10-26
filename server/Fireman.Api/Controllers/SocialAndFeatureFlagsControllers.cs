using Fireman.Application.Common.Interfaces;
using Fireman.Application.Social;
using Fireman.Contracts.Features;
using Fireman.Contracts.Social;
using Fireman.Shared.Constants;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Fireman.Api.Controllers;

[ApiController]
[Route("api/v1/social")]
[Authorize]
public class SocialController : BaseApiController
{
    private readonly ISocialService _socialService;

    public SocialController(ISocialService socialService)
    {
        _socialService = socialService;
    }

    [HttpGet("friends")]
    public async Task<IActionResult> GetFriends(CancellationToken ct)
    {
        var result = await _socialService.GetFriendsAsync(ct);
        return HandleResult(result);
    }

    [HttpPost("friends/request")]
    public async Task<IActionResult> SendFriendRequest([FromBody] SendFriendRequest request, CancellationToken ct)
    {
        var result = await _socialService.SendFriendRequestAsync(request, ct);
        return HandleResult(result);
    }

    [HttpPost("friends/request-by-username")]
    public async Task<IActionResult> AddFriendByUsername([FromBody] AddFriendByUsernameRequest request, CancellationToken ct)
    {
        var result = await _socialService.AddFriendByUsernameAsync(request, ct);
        return HandleResult(result);
    }

    [HttpPost("friends/respond")]
    public async Task<IActionResult> RespondFriendRequest([FromBody] RespondFriendRequest request, CancellationToken ct)
    {
        var result = await _socialService.RespondFriendRequestAsync(request, ct);
        return HandleResult(result);
    }

    [HttpGet("friends/{friendId:guid}/messages")]
    public async Task<IActionResult> GetMessages(Guid friendId, CancellationToken ct) =>
        HandleResult(await _socialService.GetMessagesAsync(friendId, ct));

    [HttpPost("friends/{friendId:guid}/messages")]
    public async Task<IActionResult> SendMessage(Guid friendId, [FromBody] SendDirectMessageRequest request, CancellationToken ct) =>
        HandleResult(await _socialService.SendMessageAsync(friendId, request, ct));

    [HttpPost("reports")]
    public async Task<IActionResult> SubmitReport([FromBody] SubmitReportRequest request, CancellationToken ct)
    {
        var result = await _socialService.SubmitReportAsync(request, ct);
        return HandleResult(result);
    }
}

[ApiController]
[Route("api/v1/feature-flags")]
public class FeatureFlagsController : BaseApiController
{
    private readonly IFeatureFlagService _featureFlagService;

    public FeatureFlagsController(IFeatureFlagService featureFlagService)
    {
        _featureFlagService = featureFlagService;
    }

    [HttpGet]
    [AllowAnonymous]
    public async Task<IActionResult> GetAllFlags(CancellationToken ct)
    {
        var flags = await _featureFlagService.GetAllFlagsAsync(ct);
        return Ok(flags);
    }

    [HttpPost]
    [Authorize(Policy = PolicyNames.RequireAdmin)]
    public async Task<IActionResult> SetFlag([FromBody] SetFeatureFlagRequest request, CancellationToken ct)
    {
        await _featureFlagService.SetFlagAsync(request.FeatureName, request.IsEnabled, ct);
        return Ok(new { Success = true, request.FeatureName, request.IsEnabled });
    }
}

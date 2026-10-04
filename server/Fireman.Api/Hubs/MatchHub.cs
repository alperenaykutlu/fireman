using Fireman.Application.Common.Interfaces;
using Fireman.Contracts.Matches;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace Fireman.Api.Hubs;

[Authorize]
public class MatchHub : Hub
{
    private readonly ICurrentUser _currentUser;
    private readonly ILogger<MatchHub> _logger;

    public MatchHub(ICurrentUser currentUser, ILogger<MatchHub> logger)
    {
        _currentUser = currentUser;
        _logger = logger;
    }

    public async Task JoinMatchRoom(string matchId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, matchId);
        _logger.LogInformation("User {UserId} joined match room {MatchId}", _currentUser.UserId, matchId);

        await Clients.OthersInGroup(matchId).SendAsync("PlayerJoined", new
        {
            UserId = _currentUser.UserId,
            Username = _currentUser.Username
        });
    }

    public async Task LeaveMatchRoom(string matchId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, matchId);
        _logger.LogInformation("User {UserId} left match room {MatchId}", _currentUser.UserId, matchId);

        await Clients.OthersInGroup(matchId).SendAsync("PlayerLeft", new
        {
            UserId = _currentUser.UserId
        });
    }

    public async Task SendMovement(string matchId, PlayerMovementDto movement)
    {
        // Broadcast movement update to other players in the room
        await Clients.OthersInGroup(matchId).SendAsync("PlayerMoved", movement);
    }

    public async Task SendFireSuppression(string matchId, FireSuppressionActionDto action)
    {
        _logger.LogInformation("Fire suppression action from user {UserId} on fire {FireId}", action.UserId, action.FireInstanceId);
        await Clients.Group(matchId).SendAsync("FireSuppressionUpdated", action);
    }

    public async Task SendChatMessage(string matchId, string message)
    {
        if (string.IsNullOrWhiteSpace(message) || message.Length > 200)
            return;

        // Simple profanity / sanity filter
        var cleanMessage = message.Replace("script", "[filtered]");

        var chatDto = new MatchChatMessageDto(
            _currentUser.UserId ?? Guid.Empty,
            _currentUser.Username ?? "Unknown",
            cleanMessage,
            DateTime.UtcNow);

        await Clients.Group(matchId).SendAsync("ChatMessageReceived", chatDto);
    }

    public async Task SetPlayerReady(string matchId, bool isReady)
    {
        await Clients.Group(matchId).SendAsync("PlayerReadyChanged", new
        {
            UserId = _currentUser.UserId,
            IsReady = isReady
        });
    }
}

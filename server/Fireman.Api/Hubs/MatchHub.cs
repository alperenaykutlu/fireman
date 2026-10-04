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
    private readonly Fireman.Application.AntiCheat.IAntiCheatValidationService _antiCheatService;
    private static readonly System.Collections.Concurrent.ConcurrentDictionary<Guid, (PlayerMovementDto LastMove, DateTime Timestamp)> _lastMovements = new();
    private static readonly System.Collections.Concurrent.ConcurrentDictionary<Guid, DateTime> _lastSuppressionTimes = new();

    public MatchHub(
        ICurrentUser currentUser,
        ILogger<MatchHub> logger,
        Fireman.Application.AntiCheat.IAntiCheatValidationService antiCheatService)
    {
        _currentUser = currentUser;
        _logger = logger;
        _antiCheatService = antiCheatService;
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
        if (_currentUser.UserId.HasValue)
        {
            _lastMovements.TryRemove(_currentUser.UserId.Value, out _);
            _lastSuppressionTimes.TryRemove(_currentUser.UserId.Value, out _);
        }

        await Groups.RemoveFromGroupAsync(Context.ConnectionId, matchId);
        _logger.LogInformation("User {UserId} left match room {MatchId}", _currentUser.UserId, matchId);

        await Clients.OthersInGroup(matchId).SendAsync("PlayerLeft", new
        {
            UserId = _currentUser.UserId
        });
    }

    public async Task SendMovement(string matchId, PlayerMovementDto movement)
    {
        if (!_currentUser.UserId.HasValue)
            return;

        var userId = _currentUser.UserId.Value;
        var now = DateTime.UtcNow;

        if (_lastMovements.TryGetValue(userId, out var lastEntry))
        {
            double deltaSeconds = (now - lastEntry.Timestamp).TotalSeconds;
            if (deltaSeconds >= 0.05) // En az 50ms aralık
            {
                var validation = await _antiCheatService.ValidateMovementAsync(
                    userId,
                    movement,
                    lastEntry.LastMove,
                    deltaSeconds);

                if (!validation.IsValid)
                {
                    _logger.LogWarning("AntiCheat movement violation for user {UserId}: {Reason}", userId, validation.ViolationReason);
                    await Clients.Caller.SendAsync("CheatViolationAlert", validation.ViolationReason);
                    return;
                }
            }
        }

        _lastMovements[userId] = (movement, now);

        // Broadcast verified movement update to other players in the room
        await Clients.OthersInGroup(matchId).SendAsync("PlayerMoved", movement);
    }

    public async Task SendFireSuppression(string matchId, FireSuppressionActionDto action)
    {
        if (!_currentUser.UserId.HasValue)
            return;

        var userId = _currentUser.UserId.Value;
        var now = DateTime.UtcNow;
        double deltaSeconds = 1.0;

        if (_lastSuppressionTimes.TryGetValue(userId, out var lastTime))
        {
            deltaSeconds = (now - lastTime).TotalSeconds;
        }
        _lastSuppressionTimes[userId] = now;

        var validation = await _antiCheatService.ValidateWaterSuppressionAsync(
            userId,
            action.WaterVolume,
            action.Extinguished ? 100.0f : 10.0f,
            deltaSeconds);

        if (!validation.IsValid)
        {
            _logger.LogWarning("AntiCheat water suppression violation for user {UserId}: {Reason}", userId, validation.ViolationReason);
            await Clients.Caller.SendAsync("CheatViolationAlert", validation.ViolationReason);
            return;
        }

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

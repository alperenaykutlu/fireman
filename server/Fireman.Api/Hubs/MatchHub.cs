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
    private readonly IMatchHostManager _matchHostManager;
    private static readonly System.Collections.Concurrent.ConcurrentDictionary<Guid, (PlayerInputDto LastInput, DateTime Timestamp)> _lastInputs = new();

    public MatchHub(
        ICurrentUser currentUser,
        ILogger<MatchHub> logger,
        Fireman.Application.AntiCheat.IAntiCheatValidationService antiCheatService,
        IMatchHostManager matchHostManager)
    {
        _currentUser = currentUser;
        _logger = logger;
        _antiCheatService = antiCheatService;
        _matchHostManager = matchHostManager;
    }

    public async Task JoinMatchRoom(string matchId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, matchId);
        _logger.LogInformation("User {UserId} joined match room {MatchId}", _currentUser.UserId, matchId);

        // Ensure 30Hz MatchSimulation host is running for this room
        _matchHostManager.CreateOrJoinMatch(matchId, playerCount: 4);

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
            _lastInputs.TryRemove(_currentUser.UserId.Value, out _);
        }

        await Groups.RemoveFromGroupAsync(Context.ConnectionId, matchId);
        _logger.LogInformation("User {UserId} left match room {MatchId}", _currentUser.UserId, matchId);

        await Clients.OthersInGroup(matchId).SendAsync("PlayerLeft", new
        {
            UserId = _currentUser.UserId
        });
    }

    public async Task SendPlayerInput(string matchId, PlayerInputDto input)
    {
        if (!_currentUser.UserId.HasValue)
            return;

        var userId = _currentUser.UserId.Value;
        var now = DateTime.UtcNow;

        if (_lastInputs.TryGetValue(userId, out var lastEntry))
        {
            double deltaSeconds = (now - lastEntry.Timestamp).TotalSeconds;
            var validation = await _antiCheatService.ValidateInputAsync(
                userId,
                input,
                lastEntry.LastInput,
                deltaSeconds);

            if (!validation.IsValid)
            {
                _logger.LogWarning("AntiCheat grid input violation for user {UserId}: {Reason}", userId, validation.ViolationReason);
                await Clients.Caller.SendAsync("CheatViolationAlert", validation.ViolationReason);
                return;
            }
        }

        _lastInputs[userId] = (input, now);

        // 1. Direct feed to 30Hz authoritative GameCore loop
        _matchHostManager.EnqueueInput(matchId, input);

        // 2. Broadcast input for peer prediction / client interpolation
        await Clients.OthersInGroup(matchId).SendAsync("PlayerInputReceived", input);
    }

    public async Task BroadcastWorldSnapshot(string matchId, WorldSnapshotDto snapshot)
    {
        // Typically invoked by server simulation host
        await Clients.Group(matchId).SendAsync("WorldSnapshotReceived", snapshot);
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

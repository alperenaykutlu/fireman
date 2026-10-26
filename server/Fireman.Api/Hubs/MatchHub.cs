using System.Collections.Concurrent;
using Fireman.Application.Common.Interfaces;
using Fireman.Application.Matches;
using Fireman.Contracts.Matches;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using Microsoft.Extensions.Configuration;

namespace Fireman.Api.Hubs;

[Authorize]
public sealed class MatchHub : Hub
{
    private static readonly ConcurrentDictionary<string, string> ConnectionMatches = new();
    private static readonly ConcurrentDictionary<Guid, (PlayerInputDto LastInput, DateTime Timestamp)> LastInputs = new();
    private static readonly ConcurrentDictionary<string, CancellationTokenSource> ReconnectGrace = new();
    private readonly TimeSpan _reconnectGracePeriod;

    private readonly ICurrentUser _currentUser;
    private readonly ILogger<MatchHub> _logger;
    private readonly Fireman.Application.AntiCheat.IAntiCheatValidationService _antiCheatService;
    private readonly IMatchHostManager _matchHostManager;
    private readonly IMatchService _matchService;

    public MatchHub(
        ICurrentUser currentUser,
        ILogger<MatchHub> logger,
        Fireman.Application.AntiCheat.IAntiCheatValidationService antiCheatService,
        IMatchHostManager matchHostManager,
        IMatchService matchService,
        IConfiguration configuration)
    {
        _currentUser = currentUser;
        _logger = logger;
        _antiCheatService = antiCheatService;
        _matchHostManager = matchHostManager;
        _matchService = matchService;
        var reconnectSeconds = configuration.GetValue("Game:ReconnectSeconds", 20);
        if (reconnectSeconds is < 5 or > 120)
            throw new InvalidOperationException("Game:ReconnectSeconds must be between 5 and 120.");
        _reconnectGracePeriod = TimeSpan.FromSeconds(reconnectSeconds);
    }

    public async Task JoinMatchRoom(string matchId)
    {
        if (!_currentUser.UserId.HasValue || !Guid.TryParse(matchId, out var parsedMatchId))
            throw new HubException("Geçersiz oyun odası veya oyuncu oturumu.");

        var matchResult = await _matchService.GetMatchAsync(parsedMatchId, Context.ConnectionAborted);
        if (!matchResult.IsSuccess || !matchResult.Value.Players.Any(p => p.UserId == _currentUser.UserId.Value))
            throw new HubException("Bu oyun odasına katılma yetkin yok.");

        var canonicalMatchId = parsedMatchId.ToString("D");
        var graceKey = CreateGraceKey(parsedMatchId, _currentUser.UserId.Value);
        if (ReconnectGrace.TryRemove(graceKey, out var pendingGrace))
        {
            pendingGrace.Cancel();
            pendingGrace.Dispose();
        }

        if (ConnectionMatches.TryGetValue(Context.ConnectionId, out var previousMatch) && previousMatch != canonicalMatchId)
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, previousMatch, Context.ConnectionAborted);

        _matchHostManager.CreateOrJoinMatch(canonicalMatchId, matchResult.Value.MaxPlayers);
        _matchHostManager.RegisterPlayer(canonicalMatchId, _currentUser.UserId.Value, _currentUser.Username ?? "Oyuncu");
        await Groups.AddToGroupAsync(Context.ConnectionId, canonicalMatchId, Context.ConnectionAborted);
        ConnectionMatches[Context.ConnectionId] = canonicalMatchId;

        await Clients.OthersInGroup(canonicalMatchId).SendAsync("PlayerJoined", new
        {
            UserId = _currentUser.UserId.Value.ToString("D"),
            Username = _currentUser.Username ?? "Oyuncu"
        }, Context.ConnectionAborted);
    }

    public async Task LeaveMatchRoom(string matchId)
    {
        if (!_currentUser.UserId.HasValue || !Guid.TryParse(matchId, out var parsedMatchId)) return;
        var canonicalMatchId = parsedMatchId.ToString("D");
        if (!ConnectionMatches.TryRemove(Context.ConnectionId, out var joinedMatch) || joinedMatch != canonicalMatchId) return;

        await Groups.RemoveFromGroupAsync(Context.ConnectionId, canonicalMatchId, Context.ConnectionAborted);
        CancelReconnectGrace(parsedMatchId, _currentUser.UserId.Value);
        LastInputs.TryRemove(_currentUser.UserId.Value, out _);
        await _matchService.LeaveMatchAsync(parsedMatchId, Context.ConnectionAborted);
        await Clients.OthersInGroup(canonicalMatchId).SendAsync("PlayerLeft", new { UserId = _currentUser.UserId.Value.ToString("D") }, Context.ConnectionAborted);
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        if (_currentUser.UserId.HasValue && ConnectionMatches.TryRemove(Context.ConnectionId, out var matchId))
        {
            var userId = _currentUser.UserId.Value;
            var matchGuid = Guid.Parse(matchId);
            var graceKey = CreateGraceKey(matchGuid, userId);
            var grace = new CancellationTokenSource();
            if (ReconnectGrace.AddOrUpdate(graceKey, grace, (_, old) =>
                {
                    old.Cancel();
                    old.Dispose();
                    return grace;
                }) == grace)
            {
                await Clients.Group(matchId).SendAsync("PlayerConnectionLost", new
                {
                    UserId = userId.ToString("D"),
                    ReconnectInSeconds = (int)_reconnectGracePeriod.TotalSeconds
                });
                _ = ExpireReconnectGraceAsync(graceKey, matchGuid, userId, matchId, grace);
            }
        }
        await base.OnDisconnectedAsync(exception);
    }

    public async Task SendPlayerInput(string matchId, PlayerInputDto input)
    {
        if (!_currentUser.UserId.HasValue || !Guid.TryParse(matchId, out var parsedMatchId)) return;
        var userId = _currentUser.UserId.Value;
        var canonicalMatchId = parsedMatchId.ToString("D");
        if (!ConnectionMatches.TryGetValue(Context.ConnectionId, out var joinedMatch) || joinedMatch != canonicalMatchId ||
            !Guid.TryParse(input.MatchId, out var inputMatchId) || inputMatchId != parsedMatchId ||
            !Guid.TryParse(input.UserId, out var inputUserId) || inputUserId != userId || input.MoveDir > 4)
            return;

        var now = DateTime.UtcNow;
        if (LastInputs.TryGetValue(userId, out var lastEntry))
        {
            // Cap a client at 50 packets/second; normal play sends one held input per 30Hz tick.
            var deltaSeconds = (now - lastEntry.Timestamp).TotalSeconds;
            if (deltaSeconds < 0.02) return;
            var validation = await _antiCheatService.ValidateInputAsync(userId, input, lastEntry.LastInput, deltaSeconds, Context.ConnectionAborted);
            if (!validation.IsValid)
            {
                _logger.LogWarning("Realtime input rejected for user {UserId}: {Reason}", userId, validation.ViolationReason);
                await Clients.Caller.SendAsync("CheatViolationAlert", validation.ViolationReason, Context.ConnectionAborted);
                return;
            }
        }

        LastInputs[userId] = (input, now);
        _matchHostManager.EnqueueInput(canonicalMatchId, input);
        await Clients.OthersInGroup(canonicalMatchId).SendAsync("PlayerInputReceived", input, Context.ConnectionAborted);
    }

    public Task<long> Ping(long clientTimestamp) => Task.FromResult(DateTimeOffset.UtcNow.ToUnixTimeMilliseconds());

    public async Task SendChatMessage(string matchId, string message)
    {
        if (string.IsNullOrWhiteSpace(message) || message.Length > 200 || !TryGetJoinedMatch(matchId, out var canonicalMatchId)) return;
        var chatDto = new MatchChatMessageDto(_currentUser.UserId ?? Guid.Empty, _currentUser.Username ?? "Oyuncu", message.Trim(), DateTime.UtcNow);
        await Clients.Group(canonicalMatchId).SendAsync("ChatMessageReceived", chatDto, Context.ConnectionAborted);
    }

    public async Task SetPlayerReady(string matchId, bool isReady)
    {
        if (!TryGetJoinedMatch(matchId, out var canonicalMatchId)) return;
        await Clients.Group(canonicalMatchId).SendAsync("PlayerReadyChanged", new
        {
            UserId = _currentUser.UserId?.ToString("D"),
            IsReady = isReady
        }, Context.ConnectionAborted);
    }

    private bool TryGetJoinedMatch(string matchId, out string canonicalMatchId)
    {
        canonicalMatchId = string.Empty;
        if (!Guid.TryParse(matchId, out var id) || !ConnectionMatches.TryGetValue(Context.ConnectionId, out var joined) || joined != id.ToString("D")) return false;
        canonicalMatchId = joined;
        return true;
    }

    private async Task ExpireReconnectGraceAsync(string key, Guid matchId, Guid userId, string groupName, CancellationTokenSource grace)
    {
        try
        {
            await Task.Delay(_reconnectGracePeriod, grace.Token);
            if (ReconnectGrace.TryRemove(new KeyValuePair<string, CancellationTokenSource>(key, grace)))
            {
                LastInputs.TryRemove(userId, out _);
                await _matchService.LeaveMatchAsync(matchId, grace.Token);
                await Clients.Group(groupName).SendAsync("PlayerLeft", new { UserId = userId.ToString("D") });
            }
        }
        catch (OperationCanceledException) { }
        catch (Exception exception) { _logger.LogWarning(exception, "Could not expire reconnect grace for {UserId} in match {MatchId}", userId, matchId); }
        finally { grace.Dispose(); }
    }

    private static string CreateGraceKey(Guid matchId, Guid userId) => $"{matchId:D}:{userId:D}";

    private static void CancelReconnectGrace(Guid matchId, Guid userId)
    {
        if (ReconnectGrace.TryRemove(CreateGraceKey(matchId, userId), out var grace))
        {
            grace.Cancel();
            grace.Dispose();
        }
    }
}

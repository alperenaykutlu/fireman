using Fireman.Application.Common.Interfaces;
using Fireman.Contracts.Social;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace Fireman.Api.Hubs;

[Authorize]
public class SocialHub : Hub
{
    private readonly ICurrentUser _currentUser;
    private readonly ILogger<SocialHub> _logger;

    public SocialHub(ICurrentUser currentUser, ILogger<SocialHub> logger)
    {
        _currentUser = currentUser;
        _logger = logger;
    }

    // --- Clan Chat & Presence ---
    public async Task JoinClanChannel(string clanId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"clan_{clanId}");
        _logger.LogInformation("User {UserId} joined clan channel {ClanId}", _currentUser.UserId, clanId);
    }

    public async Task LeaveClanChannel(string clanId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"clan_{clanId}");
    }

    public async Task SendClanMessage(string clanId, string message)
    {
        if (string.IsNullOrWhiteSpace(message) || message.Length > 200)
            return;

        var chatDto = new
        {
            SenderId = _currentUser.UserId,
            SenderName = _currentUser.Username,
            Message = message.Replace("<script", "[filtered]"),
            Timestamp = DateTime.UtcNow
        };

        await Clients.Group($"clan_{clanId}").SendAsync("ClanMessageReceived", chatDto);
    }

    // --- Party System (2-4 players joint matchmaking) ---
    public async Task JoinParty(string partyId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"party_{partyId}");
        await Clients.OthersInGroup($"party_{partyId}").SendAsync("PartyMemberJoined", new
        {
            UserId = _currentUser.UserId,
            Username = _currentUser.Username
        });
    }

    public async Task LeaveParty(string partyId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"party_{partyId}");
        await Clients.OthersInGroup($"party_{partyId}").SendAsync("PartyMemberLeft", new
        {
            UserId = _currentUser.UserId
        });
    }

    // --- Quick Chat & Emote in Match ---
    public async Task SendQuickEmote(string matchId, string emoteCode)
    {
        if (!_currentUser.UserId.HasValue) return;

        var emote = new QuickChatEmoteDto(
            _currentUser.UserId.Value,
            _currentUser.Username ?? "Player",
            emoteCode,
            DateTime.UtcNow
        );

        await Clients.Group(matchId).SendAsync("QuickEmoteReceived", emote);
    }
}

namespace Fireman.Contracts.Social;

public record CreateClanRequestDto(
    string Name,
    string Tag,
    string Description,
    string BadgeIcon
);

public record ClanDto(
    Guid Id,
    string Name,
    string Tag,
    string Description,
    string BadgeIcon,
    int Level,
    int MemberCount,
    List<ClanMemberDto> Members
);

public record ClanMemberDto(
    Guid UserId,
    string Username,
    byte Role,
    DateTime JoinedAt
);

public record PartyLobbyDto(
    Guid PartyId,
    Guid LeaderUserId,
    List<Guid> MemberUserIds,
    bool InMatchmakingQueue
);

public record QuickChatEmoteDto(
    Guid SenderUserId,
    string SenderUsername,
    string EmoteCode, // e.g. "nice_bomb", "help", "gg", "well_played"
    DateTime TimestampUtc
);

using Fireman.Shared.Enums;

namespace Fireman.Contracts.Social;

public record SendFriendRequest(Guid TargetUserId);
public record AddFriendByUsernameRequest(string Username);

public record RespondFriendRequest(Guid FriendshipId, bool Accept);

public record FriendDto(
    Guid FriendshipId,
    Guid FriendUserId,
    string FriendUsername,
    FriendshipStatus Status,
    DateTime CreatedAt,
    bool IsIncoming
);

public record SendDirectMessageRequest(string Message);
public record DirectMessageDto(Guid Id, Guid SenderUserId, string SenderUsername, string Message, DateTime SentAt);

public record SubmitReportRequest(
    Guid ReportedUserId,
    ReportReason Reason,
    string Description
);

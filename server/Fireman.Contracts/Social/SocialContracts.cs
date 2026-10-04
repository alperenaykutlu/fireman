using Fireman.Shared.Enums;

namespace Fireman.Contracts.Social;

public record SendFriendRequest(Guid TargetUserId);

public record RespondFriendRequest(Guid FriendshipId, bool Accept);

public record FriendDto(
    Guid FriendshipId,
    Guid FriendUserId,
    string FriendUsername,
    FriendshipStatus Status,
    DateTime CreatedAt
);

public record SubmitReportRequest(
    Guid ReportedUserId,
    ReportReason Reason,
    string Description
);

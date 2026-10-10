namespace Fireman.Contracts.Analytics;

public record AnalyticsEventDto(
    string EventName,
    Guid? UserId,
    string SessionId,
    DateTime TimestampUtc,
    Dictionary<string, object>? Parameters
);

public static class AnalyticsEventNames
{
    public const string SessionStart = "session_start";
    public const string MatchStart = "match_start";
    public const string MatchEnd = "match_end";
    public const string PowerUpCollected = "powerup_collected";
    public const string PurchaseCompleted = "purchase_completed";
    public const string TutorialCompleted = "tutorial_completed";
    public const string CheatFlagged = "cheat_flagged";
}

namespace Fireman.Shared.Constants;

public static class GameLimits
{
    public const int MinUsernameLength = 3;
    public const int MaxUsernameLength = 20;
    public const int MaxEquippedItems = 11;
    public const int MaxInventoryCapacity = 500;
    public const int MaxConcurrentMatchesPerUser = 1;
    public const int MaxMissionsPerDay = 20;
    public const int MaxScorePerRescue = 1000;
    public const int RateLimitPerMinuteAuth = 10;
    public const int RateLimitPerMinuteGeneral = 120;
}

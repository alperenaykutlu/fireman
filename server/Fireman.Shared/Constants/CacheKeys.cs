namespace Fireman.Shared.Constants;

public static class CacheKeys
{
    public const string UserPrefix = "user:";
    public const string CharacterPrefix = "char:";
    public const string LeaderboardGlobal = "leaderboard:global";
    public const string LeaderboardWeekly = "leaderboard:weekly";
    public const string ItemDefinitions = "items:definitions";

    public static string User(Guid userId) => $"{UserPrefix}{userId}";
    public static string Character(Guid characterId) => $"{CharacterPrefix}{characterId}";
}

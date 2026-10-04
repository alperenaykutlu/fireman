namespace Fireman.Shared.Constants;

public static class CacheKeys
{
    public const string Prefix = "fireman";

    public const string LeaderboardGlobal = "fireman:leaderboard:global";
    public const string LeaderboardWeekly = "fireman:leaderboard:weekly";
    public const string ItemDefinitions = "fireman:items:definitions";

    public static string User(Guid userId) => $"{Prefix}:user:{userId}";
    public static string Character(Guid characterId) => $"{Prefix}:character:{characterId}";
    public static string Item(Guid itemId) => $"{Prefix}:item:{itemId}";
    public static string SeasonLeaderboard(Guid seasonId) => $"{Prefix}:leaderboard:{seasonId}";
}

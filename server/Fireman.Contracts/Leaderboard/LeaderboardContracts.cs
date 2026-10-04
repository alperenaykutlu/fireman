namespace Fireman.Contracts.Leaderboard;

public record LeaderboardEntryDto(
    int Rank,
    Guid UserId,
    string Username,
    int Score,
    int RescuesCount,
    DateTime UpdatedAt
);

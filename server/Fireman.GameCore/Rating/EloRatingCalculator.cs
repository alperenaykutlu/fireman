namespace Fireman.GameCore.Rating;

public static class EloRatingCalculator
{
    private const double KFactor = 32.0;

    /// <summary>
    /// Calculates new ratings for 2-4 players in a Free-For-All match.
    /// Placement: 1 = Winner, 2 = Runner up, etc.
    /// </summary>
    public static int[] CalculateMultiplayerRatingChanges(int[] currentRatings, int[] placements)
    {
        int n = currentRatings.Length;
        int[] deltas = new int[n];

        // Pairwise comparison: evaluate every player against every other player
        for (int i = 0; i < n; i++)
        {
            double totalDelta = 0;
            for (int j = 0; j < n; j++)
            {
                if (i == j) continue;

                // Expected score: E_i = 1 / (1 + 10^((R_j - R_i) / 400))
                double expected = 1.0 / (1.0 + Math.Pow(10, (currentRatings[j] - currentRatings[i]) / 400.0));

                // Actual score: 1.0 if placed better, 0.5 if tied, 0.0 if placed worse
                double actual = placements[i] < placements[j] ? 1.0 : (placements[i] == placements[j] ? 0.5 : 0.0);

                totalDelta += (KFactor / (n - 1)) * (actual - expected);
            }

            deltas[i] = (int)Math.Round(totalDelta);
        }

        int[] newRatings = new int[n];
        for (int i = 0; i < n; i++)
        {
            newRatings[i] = Math.Max(100, currentRatings[i] + deltas[i]);
        }

        return newRatings;
    }
}

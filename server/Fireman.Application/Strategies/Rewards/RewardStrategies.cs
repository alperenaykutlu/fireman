using Fireman.Shared.Enums;

namespace Fireman.Application.Strategies.Rewards;

public record RewardContext(
    Guid UserId,
    UserRole Role,
    int BaseCoins,
    int BaseXp,
    int RescuesCount
);

public record CalculatedReward(
    int TotalCoins,
    int TotalXp,
    double Multiplier,
    string StrategyApplied
);

public interface IRewardStrategy
{
    CalculatedReward Calculate(RewardContext context);
}

public sealed class NormalUserRewardStrategy : IRewardStrategy
{
    public CalculatedReward Calculate(RewardContext context)
    {
        double multiplier = 1.0;
        int coins = (int)(context.BaseCoins * multiplier) + (context.RescuesCount * 10);
        int xp = (int)(context.BaseXp * multiplier) + (context.RescuesCount * 25);
        return new CalculatedReward(coins, xp, multiplier, "Normal");
    }
}

public sealed class PremiumUserRewardStrategy : IRewardStrategy
{
    public CalculatedReward Calculate(RewardContext context)
    {
        double multiplier = 1.5; // 50% bonus
        int coins = (int)(context.BaseCoins * multiplier) + (context.RescuesCount * 20);
        int xp = (int)(context.BaseXp * multiplier) + (context.RescuesCount * 50);
        return new CalculatedReward(coins, xp, multiplier, "Premium (VIP 1.5x)");
    }
}

public sealed class ModeratorRewardStrategy : IRewardStrategy
{
    public CalculatedReward Calculate(RewardContext context)
    {
        double multiplier = 1.2;
        int coins = (int)(context.BaseCoins * multiplier) + (context.RescuesCount * 15);
        int xp = (int)(context.BaseXp * multiplier) + (context.RescuesCount * 30);
        return new CalculatedReward(coins, xp, multiplier, "Staff/Moderator (1.2x)");
    }
}

public interface IRewardStrategyFactory
{
    IRewardStrategy GetStrategy(UserRole role);
}

public class RewardStrategyFactory : IRewardStrategyFactory
{
    public IRewardStrategy GetStrategy(UserRole role) => role switch
    {
        UserRole.Admin or UserRole.GameMaster or UserRole.Moderator => new ModeratorRewardStrategy(),
        UserRole.User => new NormalUserRewardStrategy(),
        _ => new NormalUserRewardStrategy()
    };
}

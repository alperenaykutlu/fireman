using Fireman.Shared.Enums;

namespace Fireman.Application.Strategies.Pricing;

public record PricingContext(
    UserRole Role,
    int BasePrice
);

public record CalculatedPrice(
    int FinalPrice,
    double DiscountRate,
    string AppliedPricing
);

public interface IPricingStrategy
{
    CalculatedPrice CalculatePrice(PricingContext context);
}

public sealed class NormalPricingStrategy : IPricingStrategy
{
    public CalculatedPrice CalculatePrice(PricingContext context) =>
        new(context.BasePrice, 0.0, "Standard Pricing");
}

public sealed class VipPricingStrategy : IPricingStrategy
{
    public CalculatedPrice CalculatePrice(PricingContext context)
    {
        int discounted = (int)(context.BasePrice * 0.85); // 15% discount
        return new(discounted, 0.15, "VIP Member (15% Off)");
    }
}

public interface IPricingStrategyFactory
{
    IPricingStrategy GetStrategy(UserRole role);
}

public class PricingStrategyFactory : IPricingStrategyFactory
{
    public IPricingStrategy GetStrategy(UserRole role) => role switch
    {
        UserRole.Admin or UserRole.GameMaster => new VipPricingStrategy(),
        _ => new NormalPricingStrategy()
    };
}

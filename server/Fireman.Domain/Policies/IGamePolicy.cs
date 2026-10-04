namespace Fireman.Domain.Policies;

public record PolicyResult(bool IsAllowed, string? Reason = null)
{
    public static PolicyResult Allow() => new(true);
    public static PolicyResult Deny(string reason) => new(false, reason);
}

public interface IGamePolicy<in TContext>
{
    PolicyResult Evaluate(TContext context);
}

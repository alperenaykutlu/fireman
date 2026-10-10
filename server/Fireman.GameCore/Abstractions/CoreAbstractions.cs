namespace Fireman.GameCore.Abstractions;

public interface IClock
{
    long CurrentTimestampMs { get; }
}

public interface IRandom
{
    int Next(int minValue, int maxValue);
    int Next(int maxValue);
    double NextDouble();
}

public interface ITickSource
{
    long CurrentTick { get; }
}

using Fireman.GameCore.Abstractions;

namespace Fireman.GameCore.Randomness;

/// <summary>
/// Deterministic XorShift PRNG for cross-platform bit-level repeatability.
/// </summary>
public sealed class SeededRandom : IRandom
{
    private uint _state;

    public SeededRandom(int seed)
    {
        _state = seed == 0 ? 0x854579u : (uint)seed;
    }

    private uint NextUint()
    {
        uint x = _state;
        x ^= x << 13;
        x ^= x >> 17;
        x ^= x << 5;
        _state = x;
        return x;
    }

    public int Next(int maxValue)
    {
        if (maxValue <= 0) return 0;
        return (int)(NextUint() % (uint)maxValue);
    }

    public int Next(int minValue, int maxValue)
    {
        if (maxValue <= minValue) return minValue;
        uint range = (uint)(maxValue - minValue);
        return minValue + (int)(NextUint() % range);
    }

    public double NextDouble()
    {
        return (NextUint() & 0x7FFFFFFF) / (double)0x80000000;
    }
}

namespace Showcase;

/// <summary>
/// A simple token-bucket rate limiter.
/// </summary>
/// <remarks>
/// Present so the C# hooks have something with real structure to check:
/// <c>dotnet format whitespace</c> checks the layout against .editorconfig,
/// <c>style</c> checks the IDExxxx preferences (file-scoped namespace, braces,
/// <c>_camelCase</c> private fields) and <c>analyzers</c> the CAxxxx rules.
/// </remarks>
public sealed class TokenBucket
{
    private readonly int _capacity;
    private readonly double _refillPerSecond;
    private double _tokens;
    private DateTimeOffset _lastRefill;

    /// <summary>
    /// Initializes a new instance of the <see cref="TokenBucket"/> class.
    /// </summary>
    /// <param name="capacity">Maximum number of tokens held at once.</param>
    /// <param name="refillPerSecond">Tokens replenished per second.</param>
    /// <param name="now">The current time, injected for testability.</param>
    public TokenBucket(int capacity, double refillPerSecond, DateTimeOffset now)
    {
        if (capacity <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(capacity), "capacity must be positive");
        }

        if (refillPerSecond <= 0)
        {
            throw new ArgumentOutOfRangeException(
                nameof(refillPerSecond),
                "refill rate must be positive");
        }

        _capacity = capacity;
        _refillPerSecond = refillPerSecond;
        _tokens = capacity;
        _lastRefill = now;
    }

    /// <summary>
    /// Gets the number of whole tokens currently available.
    /// </summary>
    public int Available => (int)Math.Floor(_tokens);

    /// <summary>
    /// Attempts to take a single token.
    /// </summary>
    /// <param name="now">The current time.</param>
    /// <returns><see langword="true"/> if a token was available.</returns>
    public bool TryTake(DateTimeOffset now)
    {
        Refill(now);

        if (_tokens < 1.0)
        {
            return false;
        }

        _tokens -= 1.0;
        return true;
    }

    private void Refill(DateTimeOffset now)
    {
        double elapsedSeconds = (now - _lastRefill).TotalSeconds;
        if (elapsedSeconds <= 0)
        {
            return;
        }

        _tokens = Math.Min(_capacity, _tokens + (elapsedSeconds * _refillPerSecond));
        _lastRefill = now;
    }
}

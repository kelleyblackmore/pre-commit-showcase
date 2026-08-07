using Showcase;

DateTimeOffset now = DateTimeOffset.UnixEpoch;
TokenBucket bucket = new(capacity: 3, refillPerSecond: 1.0, now: now);

for (int attempt = 1; attempt <= 5; attempt++)
{
    bool granted = bucket.TryTake(now);
    Console.WriteLine($"attempt {attempt}: {(granted ? "allowed" : "throttled")}");
}

now = now.AddSeconds(2);
Console.WriteLine($"after 2s: {bucket.Available} tokens available");

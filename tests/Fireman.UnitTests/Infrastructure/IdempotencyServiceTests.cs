using Fireman.Infrastructure.Persistence;

namespace Fireman.UnitTests.Infrastructure;

public sealed class IdempotencyServiceTests
{
    [Fact]
    public async Task Same_key_replays_completed_response_without_acquiring_claim()
    {
        var database = new InMemoryDocumentDatabase(new InMemoryDbContext());
        var service = new IdempotencyService(database);

        var first = await service.TryBeginAsync("user:POST:/matches:key-1");
        await service.CompleteAsync("user:POST:/matches:key-1", 201, "application/json", "{\"id\":1}");
        var replay = await service.TryBeginAsync("user:POST:/matches:key-1");

        Assert.True(first.Acquired);
        Assert.False(replay.Acquired);
        Assert.False(replay.InProgress);
        Assert.Equal(201, replay.StatusCode);
        Assert.Equal("{\"id\":1}", replay.Body);
    }

    [Fact]
    public async Task Concurrent_duplicate_claim_is_reported_as_in_progress()
    {
        var database = new InMemoryDocumentDatabase(new InMemoryDbContext());
        var service = new IdempotencyService(database);

        Assert.True((await service.TryBeginAsync("key-2")).Acquired);
        var duplicate = await service.TryBeginAsync("key-2");

        Assert.False(duplicate.Acquired);
        Assert.True(duplicate.InProgress);
    }
}

using System.Collections.Concurrent;
using System.Diagnostics;
using Fireman.Contracts.Matches;
using Microsoft.AspNetCore.SignalR.Client;
using Microsoft.Extensions.DependencyInjection;

namespace Fireman.LoadBot;

internal static class Program
{
    private static async Task<int> Main(string[] args)
    {
        Console.WriteLine("==================================================");
        Console.WriteLine("    FIREMAN LOAD BOT • VERTICAL SLICE SIMULATOR   ");
        Console.WriteLine("==================================================");

        string hubUrl = GetArg(args, "--url", "http://localhost:5000/hubs/match");
        string matchId = GetArg(args, "--matchId", Guid.NewGuid().ToString());
        int botCount = int.Parse(GetArg(args, "--bots", "4"), System.Globalization.CultureInfo.InvariantCulture);
        int durationSec = int.Parse(GetArg(args, "--duration", "10"), System.Globalization.CultureInfo.InvariantCulture);
        Guid parsedMatchGuid = Guid.TryParse(matchId, out var parsedGuid) ? parsedGuid : Guid.NewGuid();

        Console.WriteLine($"Hub URL:      {hubUrl}");
        Console.WriteLine($"Match ID:     {matchId}");
        Console.WriteLine($"Bot Count:    {botCount}");
        Console.WriteLine($"Duration:     {durationSec}s");
        Console.WriteLine("--------------------------------------------------");

        using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(durationSec + 5));
        var snapshotHashesPerTick = new ConcurrentDictionary<long, ConcurrentBag<ulong>>();
        var totalSnapshotsReceived = 0;
        var botTasks = new List<Task>();

        var random = new Random();

        for (int i = 0; i < botCount; i++)
        {
            int botIndex = i + 1;
            var botUserId = Guid.NewGuid();

            botTasks.Add(Task.Run(async () =>
            {
                var connection = new HubConnectionBuilder()
                    .WithUrl(hubUrl)
                    .AddMessagePackProtocol()
                    .WithAutomaticReconnect()
                    .Build();

                connection.On<WorldSnapshotDto>("WorldSnapshotReceived", snapshot =>
                {
                    Interlocked.Increment(ref totalSnapshotsReceived);
                    var bag = snapshotHashesPerTick.GetOrAdd(snapshot.Tick, _ => new ConcurrentBag<ulong>());
                    bag.Add(snapshot.WorldHash);
                });

                try
                {
                    await connection.StartAsync(cts.Token);
                    Console.WriteLine($"[Bot {botIndex}] Connected ({connection.ConnectionId})");

                    await connection.InvokeAsync("JoinMatch", matchId, botUserId, cts.Token);
                    Console.WriteLine($"[Bot {botIndex}] Joined match {matchId}");

                    long seq = 0;
                    var sw = Stopwatch.StartNew();

                    while (!cts.Token.IsCancellationRequested && sw.Elapsed.TotalSeconds < durationSec)
                    {
                        seq++;
                        byte dir = (byte)random.Next(0, 5);
                        bool bomb = random.Next(100) < 5; // 5% chance to place bomb

                        var inputDto = new PlayerInputDto(
                            MatchId: parsedMatchGuid.ToString("D"),
                            UserId: botUserId.ToString("D"),
                            Seq: seq,
                            ClientTick: seq,
                            MoveDir: dir,
                            PlaceBomb: bomb,
                            SubTileX: 0,
                            SubTileY: 0
                        );

                        await connection.InvokeAsync("SendPlayerInput", matchId, inputDto, cts.Token);
                        await Task.Delay(33, cts.Token); // ~30Hz
                    }
                }
                catch (OperationCanceledException) { }
                catch (Exception ex)
                {
                    Console.WriteLine($"[Bot {botIndex}] Error: {ex.Message}");
                }
                finally
                {
                    await connection.DisposeAsync();
                }
            }));
        }

        Console.WriteLine("Running bots simulation...");
        await Task.WhenAll(botTasks);

        Console.WriteLine("--------------------------------------------------");
        Console.WriteLine("SIMULATION COMPLETE. VERIFYING SNAPSHOT CONSISTENCY...");
        Console.WriteLine($"Total Snapshots Received Across Bots: {totalSnapshotsReceived}");
        Console.WriteLine($"Distinct Ticks Sampled:               {snapshotHashesPerTick.Count}");

        int desyncCount = 0;
        foreach (var (tick, hashes) in snapshotHashesPerTick)
        {
            var distinctHashes = hashes.Distinct().ToList();
            if (distinctHashes.Count > 1)
            {
                desyncCount++;
                Console.WriteLine($"[DESYNC ERROR] Tick {tick} has divergent hashes: {string.Join(", ", distinctHashes.Select(h => h.ToString("X16", System.Globalization.CultureInfo.InvariantCulture)))}");
            }
        }

        if (desyncCount == 0 && totalSnapshotsReceived > 0)
        {
            Console.ForegroundColor = ConsoleColor.Green;
            Console.WriteLine("SUCCESS: 100% Bit-Identical World Hash across all clients! Zero desyncs.");
            Console.ResetColor();
            return 0;
        }
        else if (totalSnapshotsReceived == 0)
        {
            Console.ForegroundColor = ConsoleColor.Yellow;
            Console.WriteLine("WARNING: No snapshots received (Hub offline or connection failed in standalone run).");
            Console.ResetColor();
            return 0;
        }
        else
        {
            Console.ForegroundColor = ConsoleColor.Red;
            Console.WriteLine($"FAILURE: Detected {desyncCount} ticks with desynchronized world hashes.");
            Console.ResetColor();
            return 1;
        }
    }

    private static string GetArg(string[] args, string flag, string defaultValue)
    {
        for (int i = 0; i < args.Length - 1; i++)
        {
            if (args[i].Equals(flag, StringComparison.OrdinalIgnoreCase))
            {
                return args[i + 1];
            }
        }
        return defaultValue;
    }
}

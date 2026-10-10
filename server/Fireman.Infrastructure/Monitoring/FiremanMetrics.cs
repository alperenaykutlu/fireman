using System.Diagnostics.Metrics;

namespace Fireman.Infrastructure.Monitoring;

public static class FiremanMetrics
{
    private static readonly Meter Meter = new("Fireman.Observability", "1.0.0");

    // SRE SLO & SLI Metrics (WP15)
    public static readonly Counter<long> ApiRequestCount =
        Meter.CreateCounter<long>("fireman_api_requests_total", description: "Toplam HTTP API istek sayısı");

    public static readonly Counter<long> ApiRequestErrorCount =
        Meter.CreateCounter<long>("fireman_api_errors_total", description: "Başarısız (5xx) HTTP API istek sayısı");

    public static readonly Histogram<double> ApiRequestDurationMs =
        Meter.CreateHistogram<double>("fireman_api_duration_ms", unit: "ms", description: "API uç nokta yanıt gecikmesi");

    public static readonly Histogram<double> TickDurationMs =
        Meter.CreateHistogram<double>("fireman_tick_duration_ms", unit: "ms", description: "Simülasyon tick süresi (Hedef: < 10ms)");

    public static readonly Counter<long> TickOverrunCount =
        Meter.CreateCounter<long>("fireman_tick_overrun_total", description: "33.3ms bütçesini aşan tick sayısı");

    public static readonly UpDownCounter<long> ActiveMatches =
        Meter.CreateUpDownCounter<long>("fireman_active_matches", description: "Mevcut aktif maç sayısı");

    public static readonly UpDownCounter<long> ConnectedPlayers =
        Meter.CreateUpDownCounter<long>("fireman_connected_players", description: "Anlık bağlı oyuncu sayısı");

    public static readonly Counter<long> AntiCheatFlagCount =
        Meter.CreateCounter<long>("fireman_anticheat_flags_total", description: "Anti-cheat tarafından bayraklanan kural ihlali sayısı");

    public static readonly Histogram<double> MatchmakingWaitSeconds =
        Meter.CreateHistogram<double>("fireman_matchmaking_wait_seconds", unit: "s", description: "Oyuncuların maç bulma bekleme süresi");
}

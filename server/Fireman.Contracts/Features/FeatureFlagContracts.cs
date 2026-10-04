namespace Fireman.Contracts.Features;

public record SetFeatureFlagRequest(string FeatureName, bool IsEnabled);

public static class FeatureNames
{
    public const string EnableMultiplayer = "EnableMultiplayer";
    public const string EnableTrading = "EnableTrading";
    public const string EnableSeasonPass = "EnableSeasonPass";
    public const string EnableAntiCheatStrict = "EnableAntiCheatStrict";
    public const string EnableVoiceChat = "EnableVoiceChat";
    public const string EnableMaintenanceMode = "EnableMaintenanceMode";
}

using System.Text.Json;
using System.Text.Json.Nodes;

namespace Fireman.Domain.SaveSystem;

public record GameSaveData(
    int SaveVersion,
    Guid UserId,
    string CharacterName,
    int Level,
    long Experience,
    Dictionary<string, string> EquippedSlots,
    Dictionary<string, object> GameSettings,
    DateTime SavedAt
);

public interface ISaveMigrationService
{
    const int CurrentSaveVersion = 3;
    GameSaveData MigrateToLatest(string rawJson);
}

public class SaveMigrationService : ISaveMigrationService
{
    public GameSaveData MigrateToLatest(string rawJson)
    {
        var node = JsonNode.Parse(rawJson)?.AsObject()
                   ?? throw new JsonException("Invalid save JSON format.");

        int version = node["saveVersion"]?.GetValue<int>()
                      ?? node["SaveVersion"]?.GetValue<int>()
                      ?? 1;

        // Migration step: v1 -> v2 (Add Level and Experience)
        if (version < 2)
        {
            node["Level"] = 1;
            node["Experience"] = 0;
            node["SaveVersion"] = 2;
            version = 2;
        }

        // Migration step: v2 -> v3 (Add EquippedSlots dictionary if missing)
        if (version < 3)
        {
            if (node["EquippedSlots"] == null)
            {
                node["EquippedSlots"] = new JsonObject();
            }
            node["SaveVersion"] = 3;
            version = 3;
        }

        return JsonSerializer.Deserialize<GameSaveData>(node.ToJsonString(), new JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true
        })!;
    }
}

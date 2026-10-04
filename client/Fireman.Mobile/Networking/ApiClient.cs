using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Fireman.Contracts.Auth;
using Fireman.Contracts.Characters;
using Fireman.Contracts.Common;
using Fireman.Contracts.Inventory;
using Fireman.Contracts.Matches;
using Fireman.Contracts.Missions;
using Fireman.Contracts.Offline;

namespace Fireman.Mobile.Networking;

public class ApiClient : IApiClient
{
    private readonly HttpClient _httpClient;
    private string? _accessToken;

    public ApiClient(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public void SetAuthToken(string token)
    {
        _accessToken = token;
        _httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
    }

    public async Task<ApiResponse<AuthResponse>> LoginAsync(LoginRequest request)
    {
        var response = await _httpClient.PostAsJsonAsync("api/v1/auth/login", request);
        var content = await response.Content.ReadFromJsonAsync<ApiResponse<AuthResponse>>();
        if (content?.Success == true && content.Data != null)
        {
            SetAuthToken(content.Data.AccessToken);
        }
        return content ?? ApiResponse<AuthResponse>.Fail("Invalid response from server.");
    }

    public async Task<ApiResponse<CharacterDto>> GetCharacterAsync()
    {
        return await _httpClient.GetFromJsonAsync<ApiResponse<CharacterDto>>("api/v1/characters/me")
               ?? ApiResponse<CharacterDto>.Fail("No character response.");
    }

    public async Task<ApiResponse<CharacterDto>> EquipItemAsync(EquipItemRequest request)
    {
        var response = await _httpClient.PostAsJsonAsync("api/v1/characters/equip", request);
        return await response.Content.ReadFromJsonAsync<ApiResponse<CharacterDto>>()
               ?? ApiResponse<CharacterDto>.Fail("Equip failed.");
    }

    public async Task<ApiResponse<IReadOnlyList<InventoryItemDto>>> GetInventoryAsync()
    {
        return await _httpClient.GetFromJsonAsync<ApiResponse<IReadOnlyList<InventoryItemDto>>>("api/v1/inventory")
               ?? ApiResponse<IReadOnlyList<InventoryItemDto>>.Fail("Inventory retrieval failed.");
    }

    public async Task<ApiResponse<InventoryItemDto>> BuyItemAsync(BuyItemRequest request)
    {
        var response = await _httpClient.PostAsJsonAsync("api/v1/inventory/buy", request);
        return await response.Content.ReadFromJsonAsync<ApiResponse<InventoryItemDto>>()
               ?? ApiResponse<InventoryItemDto>.Fail("Purchase failed.");
    }

    public async Task<ApiResponse<IReadOnlyList<MissionDto>>> GetMissionsAsync()
    {
        return await _httpClient.GetFromJsonAsync<ApiResponse<IReadOnlyList<MissionDto>>>("api/v1/missions")
               ?? ApiResponse<IReadOnlyList<MissionDto>>.Fail("Mission retrieval failed.");
    }

    public async Task<ApiResponse<MissionCompletionResultDto>> CompleteMissionAsync(CompleteMissionRequest request)
    {
        var response = await _httpClient.PostAsJsonAsync("api/v1/missions/complete", request);
        return await response.Content.ReadFromJsonAsync<ApiResponse<MissionCompletionResultDto>>()
               ?? ApiResponse<MissionCompletionResultDto>.Fail("Completion failed.");
    }

    public async Task<ApiResponse<OfflineSyncResponse>> SyncOfflineActionsAsync(OfflineSyncRequest request)
    {
        var response = await _httpClient.PostAsJsonAsync("api/v1/offline-sync", request);
        return await response.Content.ReadFromJsonAsync<ApiResponse<OfflineSyncResponse>>()
               ?? ApiResponse<OfflineSyncResponse>.Fail("Sync failed.");
    }

    public async Task<ApiResponse<MatchDto>> CreateMatchAsync(CreateMatchRequest request)
    {
        var response = await _httpClient.PostAsJsonAsync("api/v1/matches", request);
        return await response.Content.ReadFromJsonAsync<ApiResponse<MatchDto>>()
               ?? ApiResponse<MatchDto>.Fail("Match creation failed.");
    }

    public async Task<ApiResponse<MatchDto>> JoinMatchAsync(JoinMatchRequest request)
    {
        var response = await _httpClient.PostAsJsonAsync("api/v1/matches/join", request);
        return await response.Content.ReadFromJsonAsync<ApiResponse<MatchDto>>()
               ?? ApiResponse<MatchDto>.Fail("Join match failed.");
    }

    public async Task<ApiResponse<MatchDto>> GetMatchAsync(Guid matchId)
    {
        var response = await _httpClient.GetAsync($"api/v1/matches/{matchId}");
        return await response.Content.ReadFromJsonAsync<ApiResponse<MatchDto>>()
               ?? ApiResponse<MatchDto>.Fail("Get match failed.");
    }

    public async Task<ApiResponse<MatchDto>> SubmitMatchScoreAsync(SubmitMatchScoreRequest request)
    {
        var response = await _httpClient.PostAsJsonAsync("api/v1/matches/score", request);
        return await response.Content.ReadFromJsonAsync<ApiResponse<MatchDto>>()
               ?? ApiResponse<MatchDto>.Fail("Submit match score failed.");
    }
}

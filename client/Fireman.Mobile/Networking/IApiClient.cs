using Fireman.Contracts.Auth;
using Fireman.Contracts.Characters;
using Fireman.Contracts.Common;
using Fireman.Contracts.Inventory;
using Fireman.Contracts.Matches;
using Fireman.Contracts.Missions;
using Fireman.Contracts.Offline;

namespace Fireman.Mobile.Networking;

public interface IApiClient
{
    Task<ApiResponse<AuthResponse>> LoginAsync(LoginRequest request);
    Task<ApiResponse<CharacterDto>> GetCharacterAsync();
    Task<ApiResponse<CharacterDto>> EquipItemAsync(EquipItemRequest request);
    Task<ApiResponse<IReadOnlyList<InventoryItemDto>>> GetInventoryAsync();
    Task<ApiResponse<InventoryItemDto>> BuyItemAsync(BuyItemRequest request);
    Task<ApiResponse<IReadOnlyList<MissionDto>>> GetMissionsAsync();
    Task<ApiResponse<MissionCompletionResultDto>> CompleteMissionAsync(CompleteMissionRequest request);
    Task<ApiResponse<OfflineSyncResponse>> SyncOfflineActionsAsync(OfflineSyncRequest request);
    Task<ApiResponse<MatchDto>> CreateMatchAsync(CreateMatchRequest request);
    Task<ApiResponse<MatchDto>> JoinMatchAsync(JoinMatchRequest request);
    Task<ApiResponse<MatchDto>> GetMatchAsync(Guid matchId);
    Task<ApiResponse<MatchDto>> SubmitMatchScoreAsync(SubmitMatchScoreRequest request);
}

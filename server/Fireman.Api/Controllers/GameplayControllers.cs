using Fireman.Application.Characters;
using Fireman.Application.Inventory;
using Fireman.Application.Missions;
using Fireman.Contracts.Characters;
using Fireman.Contracts.Inventory;
using Fireman.Contracts.Missions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Fireman.Api.Controllers;

[ApiController]
[Route("api/v1/characters")]
[Authorize]
public class CharactersController : BaseApiController
{
    private readonly ICharacterService _characterService;

    public CharactersController(ICharacterService characterService)
    {
        _characterService = characterService;
    }

    [HttpGet("me")]
    public async Task<IActionResult> GetCharacter(CancellationToken ct)
    {
        var result = await _characterService.GetCharacterAsync(ct);
        return HandleResult(result);
    }

    [HttpPost("equip")]
    public async Task<IActionResult> EquipItem([FromBody] EquipItemRequest request, CancellationToken ct)
    {
        var result = await _characterService.EquipItemAsync(request, ct);
        return HandleResult(result);
    }

    [HttpPost("unequip")]
    public async Task<IActionResult> UnequipItem([FromBody] UnequipItemRequest request, CancellationToken ct)
    {
        var result = await _characterService.UnequipItemAsync(request, ct);
        return HandleResult(result);
    }
}

[ApiController]
[Route("api/v1/inventory")]
[Authorize]
public class InventoryController : BaseApiController
{
    private readonly IInventoryService _inventoryService;

    public InventoryController(IInventoryService inventoryService)
    {
        _inventoryService = inventoryService;
    }

    [HttpGet("shop")]
    [AllowAnonymous]
    public async Task<IActionResult> GetShopItems(CancellationToken ct)
    {
        var result = await _inventoryService.GetAvailableShopItemsAsync(ct);
        return HandleResult(result);
    }

    [HttpGet]
    public async Task<IActionResult> GetInventory(CancellationToken ct)
    {
        var result = await _inventoryService.GetUserInventoryAsync(ct);
        return HandleResult(result);
    }

    [HttpPost("buy")]
    public async Task<IActionResult> BuyItem([FromBody] BuyItemRequest request, CancellationToken ct)
    {
        var result = await _inventoryService.BuyItemAsync(request, ct);
        return HandleResult(result);
    }
}

[ApiController]
[Route("api/v1/missions")]
[Authorize]
public class MissionsController : BaseApiController
{
    private readonly IMissionService _missionService;

    public MissionsController(IMissionService missionService)
    {
        _missionService = missionService;
    }

    [HttpGet]
    public async Task<IActionResult> GetMissions(CancellationToken ct)
    {
        var result = await _missionService.GetAvailableMissionsAsync(ct);
        return HandleResult(result);
    }

    [HttpPost("start")]
    public async Task<IActionResult> StartMission([FromBody] StartMissionRequest request, CancellationToken ct)
    {
        var result = await _missionService.StartMissionAsync(request, ct);
        return HandleResult(result);
    }

    [HttpPost("complete")]
    public async Task<IActionResult> CompleteMission([FromBody] CompleteMissionRequest request, CancellationToken ct)
    {
        var result = await _missionService.CompleteMissionAsync(request, ct);
        return HandleResult(result);
    }
}

using Fireman.Application.Characters;
using Fireman.Application.Inventory;
using Fireman.Application.Missions;
using Fireman.Contracts.Characters;
using Fireman.Contracts.Inventory;
using Fireman.Contracts.Missions;
using Fireman.Application.Common.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Fireman.Api.Controllers;

[ApiController]
[Route("api/v1/characters")]
[Authorize]
public class CharactersController : BaseApiController
{
    private readonly ICharacterService _characterService;
    private readonly IDocumentDatabase _database;

    public CharactersController(ICharacterService characterService, IDocumentDatabase database)
    {
        _characterService = characterService;
        _database = database;
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

    [HttpPut("customization")]
    public async Task<IActionResult> SaveCustomization([FromBody] SaveCustomizationRequest request, CancellationToken ct)
    {
        if (!TryGetProfileId(out var id)) return BadRequest("A valid character profile id is required.");

        var record = await _database.GetAsync<Fireman.Domain.Characters.CharacterCustomization>("characterCustomizations", id.ToString(), ct);
        if (record is null)
        {
            record = new Fireman.Domain.Characters.CharacterCustomization(id, request.Gender, request.Hat,
                request.HatStyle, request.Suit, request.SuitStyle, request.Accessory, request.SkinColorValue, request.SuitColorValue, request.Mask, request.Gloves, request.Shoes, request.Bomb);
        }
        else
        {
            record.Update(request.Gender, request.Hat, request.HatStyle, request.Suit, request.SuitStyle, request.Accessory, request.SkinColorValue, request.SuitColorValue, request.Mask, request.Gloves, request.Shoes, request.Bomb);
        }
        await _database.SetAsync("characterCustomizations", id.ToString(), record, ct);
        return Ok(new { data = request });
    }

    [HttpGet("customization")]
    public async Task<IActionResult> GetCustomization(CancellationToken ct)
    {
        if (!TryGetProfileId(out var id)) return BadRequest("A valid character profile id is required.");
        var record = await _database.GetAsync<Fireman.Domain.Characters.CharacterCustomization>("characterCustomizations", id.ToString(), ct);
        return Ok(new { data = record });
    }

    private bool TryGetProfileId(out Guid id)
    {
        var identity = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value
            ?? User.FindFirst("sub")?.Value;
        id = Guid.Empty;
        return User.Identity?.IsAuthenticated == true && Guid.TryParse(identity, out id);
    }
}

public record SaveCustomizationRequest(string Gender, string Hat, int HatStyle, string Suit, int SuitStyle, string Accessory, long SkinColorValue = 4294955428L, long SuitColorValue = 4292617766L, string Mask = "Standart maske", string Gloves = "Standart eldiven", string Shoes = "Standart ayakkabı", string Bomb = "Klasik dinamit");

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

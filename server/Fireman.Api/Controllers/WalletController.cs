using Fireman.Application.Economy;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Fireman.Api.Controllers;

[ApiController]
[Route("api/v1/wallet")]
[Authorize]
public class WalletController : BaseApiController
{
    private readonly IWalletService _walletService;

    public WalletController(IWalletService walletService)
    {
        _walletService = walletService;
    }

    [HttpGet]
    public async Task<IActionResult> GetWallet(CancellationToken ct)
    {
        var result = await _walletService.GetWalletSummaryAsync(ct);
        return HandleResult(result);
    }

    [HttpGet("history")]
    public async Task<IActionResult> GetHistory(CancellationToken ct)
    {
        var result = await _walletService.GetLedgerHistoryAsync(ct);
        return HandleResult(result);
    }
}

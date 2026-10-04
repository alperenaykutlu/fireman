using Fireman.Contracts.Common;
using Fireman.Shared.Results;
using Microsoft.AspNetCore.Mvc;

namespace Fireman.Api.Controllers;

[ApiController]
[Route("api/v1/[controller]")]
public abstract class BaseApiController : ControllerBase
{
    protected IActionResult HandleResult<T>(Result<T> result)
    {
        if (result.IsSuccess)
        {
            return Ok(ApiResponse<T>.Ok(result.Value));
        }

        if (result.Error.Code.Contains("NotFound", StringComparison.OrdinalIgnoreCase))
        {
            return NotFound(ApiResponse<T>.Fail(result.Error.Message, result.Error.Code));
        }

        if (result.Error.Code.Contains("Unauthorized", StringComparison.OrdinalIgnoreCase))
        {
            return Unauthorized(ApiResponse<T>.Fail(result.Error.Message, result.Error.Code));
        }

        if (result.Error.Code.Contains("Forbidden", StringComparison.OrdinalIgnoreCase))
        {
            return StatusCode(StatusCodes.Status403Forbidden, ApiResponse<T>.Fail(result.Error.Message, result.Error.Code));
        }

        if (result.Error.Code.Contains("Conflict", StringComparison.OrdinalIgnoreCase) || result.Error.Code.Contains("Exists", StringComparison.OrdinalIgnoreCase))
        {
            return Conflict(ApiResponse<T>.Fail(result.Error.Message, result.Error.Code));
        }

        return BadRequest(ApiResponse<T>.Fail(result.Error.Message, result.Error.Code));
    }
}

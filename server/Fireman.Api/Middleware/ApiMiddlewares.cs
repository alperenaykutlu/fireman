using System.Collections.Concurrent;
using System.Net;
using System.Text.Json;
using System.Security.Cryptography;
using System.Text;
using Fireman.Application.Common.Interfaces;
using Fireman.Contracts.Common;
using Fireman.Infrastructure.Persistence;
using Fireman.Shared.Constants;
using Fireman.Shared.Exceptions;

namespace Fireman.Api.Middleware;

public class CorrelationIdMiddleware
{
    private readonly RequestDelegate _next;

    public CorrelationIdMiddleware(RequestDelegate next) => _next = next;

    public async Task InvokeAsync(HttpContext context)
    {
        var correlationId = context.Request.Headers[HeaderNames.CorrelationId].FirstOrDefault();
        if (string.IsNullOrWhiteSpace(correlationId))
        {
            correlationId = Guid.NewGuid().ToString("N");
        }

        context.Items[HeaderNames.CorrelationId] = correlationId;
        context.Response.Headers[HeaderNames.CorrelationId] = correlationId;

        await _next(context);
    }
}

public sealed class RequestConcurrencyGate
{
    private readonly SemaphoreSlim _semaphore = new(128, 128);
    public bool TryEnter() => _semaphore.Wait(0);
    public void Exit() => _semaphore.Release();
}

public sealed class RequestConcurrencyMiddleware(RequestDelegate next, RequestConcurrencyGate gate)
{
    public async Task InvokeAsync(HttpContext context)
    {
        if (context.Request.Path == "/health")
        {
            await next(context);
            return;
        }
        if (!gate.TryEnter())
        {
            context.Response.StatusCode = StatusCodes.Status503ServiceUnavailable;
            context.Response.Headers.RetryAfter = "2";
            await context.Response.WriteAsJsonAsync(ApiResponse<object>.Fail("Server is busy. Retry shortly.", "ServerBusy"));
            return;
        }
        try { await next(context); }
        finally { gate.Exit(); }
    }
}

public sealed class IdempotencyMiddleware(RequestDelegate next)
{
    private const int MaxStoredResponseBytes = 512 * 1024;

    public async Task InvokeAsync(HttpContext context, IIdempotencyService service)
    {
        var method = context.Request.Method;
        if (method is not ("POST" or "PUT" or "PATCH" or "DELETE"))
        {
            await next(context);
            return;
        }

        var suppliedKey = context.Request.Headers["X-Idempotency-Key"].FirstOrDefault();
        if (string.IsNullOrWhiteSpace(suppliedKey))
        {
            await next(context);
            return;
        }
        if (suppliedKey.Length > 128 || suppliedKey.Any(c => !(char.IsAsciiLetterOrDigit(c) || c is '-' or '_' or '.' or ':')))
        {
            context.Response.StatusCode = StatusCodes.Status400BadRequest;
            await context.Response.WriteAsJsonAsync(ApiResponse<object>.Fail("Invalid X-Idempotency-Key.", "InvalidIdempotencyKey"));
            return;
        }

        var owner = context.User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value
            ?? context.User.FindFirst("sub")?.Value
            ?? context.Connection.RemoteIpAddress?.ToString()
            ?? "unknown";
        var rawScope = $"{owner}\n{method}\n{context.Request.Path.Value?.ToUpperInvariant()}\n{suppliedKey}";
        var key = Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(rawScope)));
        var claim = await service.TryBeginAsync(key, context.RequestAborted);

        if (!claim.Acquired)
        {
            if (claim.InProgress)
            {
                context.Response.StatusCode = StatusCodes.Status409Conflict;
                context.Response.Headers.RetryAfter = "1";
                await context.Response.WriteAsJsonAsync(ApiResponse<object>.Fail("A request with this idempotency key is still processing.", "RequestInProgress"));
                return;
            }
            context.Response.StatusCode = claim.StatusCode ?? StatusCodes.Status200OK;
            context.Response.ContentType = claim.ContentType ?? "application/json";
            context.Response.Headers["Idempotency-Replayed"] = "true";
            await context.Response.WriteAsync(claim.Body ?? string.Empty, context.RequestAborted);
            return;
        }

        var originalBody = context.Response.Body;
        await using var bufferedBody = new MemoryStream();
        context.Response.Body = bufferedBody;
        try
        {
            await next(context);
            if (context.Response.StatusCode < 500 && bufferedBody.Length <= MaxStoredResponseBytes)
            {
                var body = Encoding.UTF8.GetString(bufferedBody.ToArray());
                await service.CompleteAsync(key, context.Response.StatusCode, context.Response.ContentType, body, context.RequestAborted);
            }
            else
            {
                await service.ReleaseAsync(key, context.RequestAborted);
            }
            bufferedBody.Position = 0;
            await bufferedBody.CopyToAsync(originalBody, context.RequestAborted);
        }
        catch
        {
            await service.ReleaseAsync(key, CancellationToken.None);
            throw;
        }
        finally
        {
            context.Response.Body = originalBody;
        }
    }
}

public sealed class SecurityHeadersMiddleware(RequestDelegate next)
{
    public async Task InvokeAsync(HttpContext context)
    {
        context.Response.Headers["X-Content-Type-Options"] = "nosniff";
        context.Response.Headers["X-Frame-Options"] = "DENY";
        context.Response.Headers["Referrer-Policy"] = "no-referrer";
        context.Response.Headers["Permissions-Policy"] = "camera=(), microphone=(), geolocation=()";
        await next(context);
    }
}

public class GlobalExceptionHandlingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<GlobalExceptionHandlingMiddleware> _logger;

    public GlobalExceptionHandlingMiddleware(RequestDelegate next, ILogger<GlobalExceptionHandlingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unhandled exception occurred: {Message}", ex.Message);
            await HandleExceptionAsync(context, ex);
        }
    }

    private static async Task HandleExceptionAsync(HttpContext context, Exception exception)
    {
        context.Response.ContentType = "application/json";

        var (statusCode, errorCode, message, validationErrors) = exception switch
        {
            CircuitBreakerOpenException => (HttpStatusCode.ServiceUnavailable, "Database.TemporarilyUnavailable", "Storage is temporarily unavailable. Retry shortly.", (IReadOnlyDictionary<string, string[]>?)null),
            StorageUnavailableException => (HttpStatusCode.ServiceUnavailable, "Database.Unavailable", "Storage is temporarily unavailable. Retry shortly.", (IReadOnlyDictionary<string, string[]>?)null),
            System.Data.Common.DbException => (HttpStatusCode.ServiceUnavailable, "Database.Unavailable", "Storage is temporarily unavailable. Retry shortly.", (IReadOnlyDictionary<string, string[]>?)null),
            TimeoutException => (HttpStatusCode.ServiceUnavailable, "Dependency.Timeout", "A required service timed out. Retry shortly.", (IReadOnlyDictionary<string, string[]>?)null),
            ValidationException valEx => (HttpStatusCode.BadRequest, valEx.Code, valEx.Message, valEx.Errors),
            NotFoundException notFoundEx => (HttpStatusCode.NotFound, notFoundEx.Code, notFoundEx.Message, (IReadOnlyDictionary<string, string[]>?)null),
            ForbiddenException forbiddenEx => (HttpStatusCode.Forbidden, forbiddenEx.Code, forbiddenEx.Message, (IReadOnlyDictionary<string, string[]>?)null),
            DomainException domainEx => (HttpStatusCode.BadRequest, domainEx.Code, domainEx.Message, (IReadOnlyDictionary<string, string[]>?)null),
            _ => (HttpStatusCode.InternalServerError, "Server.InternalError", "An unexpected error occurred.", (IReadOnlyDictionary<string, string[]>?)null)
        };

        context.Response.StatusCode = (int)statusCode;
        var response = ApiResponse<object>.Fail(message, errorCode, validationErrors);

        await context.Response.WriteAsync(JsonSerializer.Serialize(response, new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase
        }));
    }
}

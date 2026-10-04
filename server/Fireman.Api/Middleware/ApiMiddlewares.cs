using System.Collections.Concurrent;
using System.Net;
using System.Text.Json;
using Fireman.Contracts.Common;
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

public class RateLimitingMiddleware
{
    private readonly RequestDelegate _next;
    private static readonly ConcurrentDictionary<string, (int Count, DateTime WindowStart)> RequestCounters = new();
    private static readonly TimeSpan Window = TimeSpan.FromMinutes(1);

    public RateLimitingMiddleware(RequestDelegate next) => _next = next;

    public async Task InvokeAsync(HttpContext context)
    {
        var ip = context.Connection.RemoteIpAddress?.ToString() ?? "unknown";
        var now = DateTime.UtcNow;

        var (count, windowStart) = RequestCounters.GetOrAdd(ip, _ => (0, now));
        if (now - windowStart > Window)
        {
            RequestCounters[ip] = (1, now);
        }
        else
        {
            if (count > GameLimits.RateLimitPerMinuteGeneral)
            {
                context.Response.StatusCode = (int)HttpStatusCode.TooManyRequests;
                context.Response.ContentType = "application/json";
                var response = ApiResponse<object>.Fail("Rate limit exceeded. Please wait a minute before retrying.", "TooManyRequests");
                await context.Response.WriteAsync(JsonSerializer.Serialize(response));
                return;
            }

            RequestCounters[ip] = (count + 1, windowStart);
        }

        await _next(context);
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

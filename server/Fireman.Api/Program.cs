using System.Security.Cryptography;
using System.Threading.RateLimiting;
using Fireman.Api.Middleware;
using Fireman.Api.Services;
using Fireman.Application;
using Fireman.Application.Common.Interfaces;
using Fireman.Infrastructure;
using Fireman.Shared.Constants;
using Fireman.Shared.Enums;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.IdentityModel.Tokens;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// Add Layers
builder.Services.AddApplication();
builder.Services.AddInfrastructure(builder.Configuration);

// HTTP Context & Current User
builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<ICurrentUser, CurrentUser>();

// Controllers & JSON options
builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.Converters.Add(new System.Text.Json.Serialization.JsonStringEnumConverter());
    });

var dataProtection = builder.Services.AddDataProtection()
    .SetApplicationName(builder.Configuration["DataProtection:ApplicationName"] ?? "Fireman");
var dataProtectionKeysPath = builder.Configuration["DataProtection:KeysPath"];
if (!string.IsNullOrWhiteSpace(dataProtectionKeysPath))
    dataProtection.PersistKeysToFileSystem(new DirectoryInfo(dataProtectionKeysPath));

builder.WebHost.ConfigureKestrel(options => options.Limits.MaxRequestBodySize = 1_048_576);
builder.Services.AddRateLimiter(options =>
{
    var authPermitLimit = builder.Configuration.GetValue("RateLimiting:AuthRequestsPerMinute", GameLimits.RateLimitPerMinuteAuth);
    var generalPermitLimit = builder.Configuration.GetValue("RateLimiting:GeneralRequestsPerMinute", GameLimits.RateLimitPerMinuteGeneral);
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(context =>
    {
        var remoteAddress = context.Connection.RemoteIpAddress?.ToString() ?? "unknown";
        var isAuthentication = context.Request.Path.StartsWithSegments("/api/v1/auth", StringComparison.OrdinalIgnoreCase);
        var key = $"{remoteAddress}:{(isAuthentication ? "auth" : "general")}";
        return RateLimitPartition.GetFixedWindowLimiter(key, _ => new FixedWindowRateLimiterOptions
        {
            PermitLimit = isAuthentication ? authPermitLimit : generalPermitLimit,
            Window = TimeSpan.FromMinutes(1),
            QueueLimit = 0,
            AutoReplenishment = true
        });
    });
    options.OnRejected = async (rejection, cancellationToken) =>
    {
        rejection.HttpContext.Response.Headers.RetryAfter = "60";
        rejection.HttpContext.Response.ContentType = "application/json";
        await rejection.HttpContext.Response.WriteAsJsonAsync(
            Fireman.Contracts.Common.ApiResponse<object>.Fail("Too many requests. Retry after the indicated delay.", "TooManyRequests"),
            cancellationToken);
    };
});
builder.Services.AddSingleton<RequestConcurrencyGate>();

// CORS for Mobile & Web clients
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        var origins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>() ?? [];
        if (origins.Length > 0)
            policy.WithOrigins(origins).AllowAnyHeader().AllowAnyMethod().AllowCredentials();
    });
});

// SignalR for real-time multiplayer with MessagePack binary serialization
builder.Services.AddSignalR()
    .AddMessagePackProtocol();

// Authoritative GameCore Match Simulation Host Manager (30Hz tick)
builder.Services.AddSingleton<Fireman.Api.Hubs.IMatchHostManager, Fireman.Api.Hubs.MatchHostManager>();

// Health Checks (Section 61)
builder.Services.AddHealthChecks();

// OpenAPI
builder.Services.AddOpenApi();

// Auth secrets are supplied by the environment. Development can use fresh,
// process-local random material when .env has not been loaded; production fails closed.
var canGenerateEphemeralSecrets = builder.Environment.IsDevelopment() || builder.Environment.IsEnvironment("Testing");
var jwtPrivateKey = builder.Configuration["Jwt:SigningPrivateKeyPkcs8Base64"];
if (string.IsNullOrWhiteSpace(jwtPrivateKey))
{
    if (!canGenerateEphemeralSecrets)
        throw new InvalidOperationException("Jwt:SigningPrivateKeyPkcs8Base64 is required outside Development.");
    using var temporarySigningKey = RSA.Create(3072);
    jwtPrivateKey = Convert.ToBase64String(temporarySigningKey.ExportPkcs8PrivateKey());
    builder.Configuration["Jwt:SigningPrivateKeyPkcs8Base64"] = jwtPrivateKey;
}

foreach (var pepperKey in new[] { "Auth:RefreshTokenHashPepper", "Auth:GuestSecretHashPepper" })
{
    var encodedPepper = builder.Configuration[pepperKey];
    if (string.IsNullOrWhiteSpace(encodedPepper))
    {
        if (!canGenerateEphemeralSecrets)
            throw new InvalidOperationException($"{pepperKey} is required outside Development.");
        encodedPepper = Convert.ToBase64String(RandomNumberGenerator.GetBytes(48));
        builder.Configuration[pepperKey] = encodedPepper;
    }

    byte[] pepperBytes;
    try { pepperBytes = Convert.FromBase64String(encodedPepper); }
    catch (FormatException exception)
    {
        throw new InvalidOperationException($"{pepperKey} must be Base64-encoded random bytes.", exception);
    }
    if (pepperBytes.Length < 32)
        throw new InvalidOperationException($"{pepperKey} must contain at least 32 random bytes.");
}

using var signingRsa = RSA.Create();
try
{
    signingRsa.ImportPkcs8PrivateKey(Convert.FromBase64String(jwtPrivateKey), out _);
}
catch (Exception exception) when (exception is FormatException or CryptographicException)
{
    throw new InvalidOperationException("JWT signing key must be a Base64-encoded PKCS#8 RSA private key.");
}
if (signingRsa.KeySize < 2048)
    throw new InvalidOperationException("JWT RSA signing key must be at least 2048 bits.");

var jwtIssuer = builder.Configuration["Jwt:Issuer"];
var jwtAudience = builder.Configuration["Jwt:Audience"];
if (string.IsNullOrWhiteSpace(jwtIssuer) || string.IsNullOrWhiteSpace(jwtAudience))
    throw new InvalidOperationException("Jwt:Issuer and Jwt:Audience are required.");

var jwtValidationKeys = new List<SecurityKey>
{
    new RsaSecurityKey(signingRsa.ExportParameters(includePrivateParameters: false))
    {
        KeyId = builder.Configuration["Jwt:KeyId"] ?? "current"
    }
};
foreach (var previousKey in builder.Configuration.GetSection("Jwt:PreviousSigningPublicKeys").GetChildren())
{
    if (string.IsNullOrWhiteSpace(previousKey.Value)) continue;
    using var previousRsa = RSA.Create();
    try
    {
        previousRsa.ImportSubjectPublicKeyInfo(Convert.FromBase64String(previousKey.Value), out _);
    }
    catch (Exception exception) when (exception is FormatException or CryptographicException)
    {
        throw new InvalidOperationException("Every Jwt:PreviousSigningPublicKeys entry must be Base64-encoded SubjectPublicKeyInfo.");
    }
    if (previousRsa.KeySize < 2048)
        throw new InvalidOperationException("Previous JWT RSA public keys must be at least 2048 bits.");
    jwtValidationKeys.Add(new RsaSecurityKey(previousRsa.ExportParameters(includePrivateParameters: false))
    {
        KeyId = previousKey.Key ?? $"previous-{jwtValidationKeys.Count}"
    });
}

var clockSkewSeconds = builder.Configuration.GetValue("Jwt:ClockSkewSeconds", 5);
if (clockSkewSeconds is < 0 or > 120)
    throw new InvalidOperationException("Jwt:ClockSkewSeconds must be between 0 and 120.");

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.RequireHttpsMetadata = !builder.Environment.IsDevelopment();
    options.SaveToken = true;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuerSigningKey = true,
        IssuerSigningKeys = jwtValidationKeys,
        ValidateIssuer = true,
        ValidIssuer = jwtIssuer,
        ValidateAudience = true,
        ValidAudience = jwtAudience,
        ValidateLifetime = true,
        ClockSkew = TimeSpan.FromSeconds(clockSkewSeconds)
    };
    options.Events = new JwtBearerEvents
    {
        OnMessageReceived = context =>
        {
            // SignalR's native WebSocket clients pass bearer tokens in the query string.
            // Limit query-token extraction to hub routes so ordinary API requests still
            // require the Authorization header.
            if (context.HttpContext.Request.Path.StartsWithSegments("/hubs") &&
                context.Request.Query.TryGetValue("access_token", out var token) &&
                !string.IsNullOrEmpty(token))
            {
                context.Token = token;
            }
            return Task.CompletedTask;
        }
    };
});

// Authorization Policies
builder.Services.AddAuthorization(options =>
{
    options.AddPolicy(PolicyNames.RequireAdmin, policy => policy.RequireRole(UserRole.Admin.ToString()));
    options.AddPolicy(PolicyNames.RequireModerator, policy => policy.RequireRole(UserRole.Admin.ToString(), UserRole.Moderator.ToString()));
    options.AddPolicy(PolicyNames.RequireGameMaster, policy => policy.RequireRole(UserRole.Admin.ToString(), UserRole.GameMaster.ToString()));
    options.AddPolicy(PolicyNames.RequireUser, policy => policy.RequireRole(UserRole.User.ToString(), UserRole.Moderator.ToString(), UserRole.Admin.ToString()));
});

var app = builder.Build();

if (string.Equals(app.Configuration["Persistence:Provider"], "Postgres", StringComparison.OrdinalIgnoreCase))
{
    await using var migrationScope = app.Services.CreateAsyncScope();
    var database = migrationScope.ServiceProvider.GetRequiredService<Fireman.Infrastructure.Persistence.FiremanDbContext>();
    await database.Database.MigrateAsync();
}

// Configure the HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseMiddleware<CorrelationIdMiddleware>();
app.UseMiddleware<GlobalExceptionHandlingMiddleware>();
app.UseMiddleware<SecurityHeadersMiddleware>();
if (!app.Environment.IsDevelopment())
{
    app.UseHsts();
    app.UseHttpsRedirection();
}
app.UseRateLimiter();
app.UseMiddleware<RequestConcurrencyMiddleware>();

app.UseDefaultFiles();
app.UseStaticFiles();

app.UseCors();

app.UseAuthentication();
app.UseAuthorization();
app.UseMiddleware<IdempotencyMiddleware>();

app.MapControllers();
app.MapHub<Fireman.Api.Hubs.MatchHub>("/hubs/match");
app.MapHub<Fireman.Api.Hubs.SocialHub>("/hubs/social");
app.MapHealthChecks("/health");

// Remote Config Endpoint (LiveOps WP18)
app.MapGet("/api/v1/config/{key}", async (string key, Fireman.Application.Common.Interfaces.IRemoteConfigService configService, CancellationToken ct) =>
{
    var configJson = await configService.GetConfigJsonAsync(key, null, ct);
    return Results.Content(configJson, "application/json");
}).AllowAnonymous();

app.Run();

// For integration tests WebApplicationFactory
public partial class Program { }

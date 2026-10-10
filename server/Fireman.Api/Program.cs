using System.Text;
using Fireman.Api.Middleware;
using Fireman.Api.Services;
using Fireman.Application;
using Fireman.Application.Common.Interfaces;
using Fireman.Infrastructure;
using Fireman.Shared.Constants;
using Fireman.Shared.Enums;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;

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

// CORS for Mobile & Web clients
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.AllowAnyHeader()
              .AllowAnyMethod()
              .SetIsOriginAllowed(_ => true)
              .AllowCredentials();
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

// JWT Authentication
var jwtSecret = builder.Configuration["Jwt:SecretKey"] ?? "FiremanSuperSecretGameSecurityKeyWithAtLeast32BytesLength!";
var jwtIssuer = builder.Configuration["Jwt:Issuer"] ?? "FiremanApi";
var jwtAudience = builder.Configuration["Jwt:Audience"] ?? "FiremanClient";

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.RequireHttpsMetadata = false;
    options.SaveToken = true;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSecret)),
        ValidateIssuer = true,
        ValidIssuer = jwtIssuer,
        ValidateAudience = true,
        ValidAudience = jwtAudience,
        ValidateLifetime = true,
        ClockSkew = TimeSpan.Zero
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

// Configure the HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseMiddleware<CorrelationIdMiddleware>();
app.UseMiddleware<GlobalExceptionHandlingMiddleware>();
app.UseMiddleware<RateLimitingMiddleware>();

app.UseDefaultFiles();
app.UseStaticFiles();

app.UseCors();

app.UseAuthentication();
app.UseAuthorization();

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

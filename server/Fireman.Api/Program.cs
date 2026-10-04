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

// SignalR for real-time multiplayer
builder.Services.AddSignalR();

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

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.MapHub<Fireman.Api.Hubs.MatchHub>("/hubs/match");
app.MapHealthChecks("/health");

app.Run();

// For integration tests WebApplicationFactory
public partial class Program { }

using Fireman.Contracts.Matches;
using Fireman.Domain.AntiCheat;
using Fireman.Shared.Results;

namespace Fireman.Application.AntiCheat;

public record ValidationOutcome(
    bool IsValid,
    string? ViolationReason = null,
    AntiCheatLog? Log = null
);

public interface IAntiCheatValidationService
{
    Task<ValidationOutcome> ValidateMovementAsync(
        Guid userId,
        PlayerMovementDto newMovement,
        PlayerMovementDto? previousMovement,
        double deltaSeconds,
        CancellationToken cancellationToken = default);

    Task<ValidationOutcome> ValidateScoreSubmissionAsync(
        Guid userId,
        int scoreDelta,
        int rescuesDelta,
        double elapsedSeconds,
        CancellationToken cancellationToken = default);

    Task<ValidationOutcome> ValidateWaterSuppressionAsync(
        Guid userId,
        float waterSpent,
        float fireExtinguished,
        double deltaSeconds,
        CancellationToken cancellationToken = default);
}

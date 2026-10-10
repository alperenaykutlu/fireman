using Fireman.Contracts.Matches;
using Fireman.Domain.AntiCheat;

namespace Fireman.Application.AntiCheat;

public record ValidationOutcome(
    bool IsValid,
    string? ViolationReason = null,
    AntiCheatLog? Log = null
);

public interface IAntiCheatValidationService
{
    Task<ValidationOutcome> ValidateInputAsync(
        Guid userId,
        PlayerInputDto newInput,
        PlayerInputDto? previousInput,
        double deltaSeconds,
        CancellationToken cancellationToken = default);

    Task<ValidationOutcome> ValidateScoreSubmissionAsync(
        Guid userId,
        int scoreDelta,
        int killsDelta,
        double elapsedSeconds,
        CancellationToken cancellationToken = default);
}

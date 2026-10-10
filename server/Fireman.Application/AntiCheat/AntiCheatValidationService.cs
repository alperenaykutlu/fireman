using System.Text.Json;
using Fireman.Application.Common.Interfaces;
using Fireman.Application.Events;
using Fireman.Contracts.Matches;
using Fireman.Domain.AntiCheat;
using Fireman.Domain.Users;
using Fireman.Shared.Enums;

namespace Fireman.Application.AntiCheat;

public class AntiCheatValidationService : IAntiCheatValidationService
{
    // Grid-based limits: 256 sub-units = 1 tile.
    // Max movement speed is ~16 sub-units per tick (approx 2 tiles/sec at 30 ticks/s).
    // Allow up to 32 sub-units per tick margin for latency/speed powerups.
    private const int MaxAllowedSubUnitDeltaPerTick = 32;
    private const int TeleportSubUnitThreshold = 128; // Half a tile jump in a single tick
    private const double MaxScorePerSecond = 500.0;
    private const int MaxScorePerKill = 2500;

    private readonly IAntiCheatRepository _antiCheatRepository;
    private readonly IUserRepository _userRepository;
    private readonly IEventBus _eventBus;
    private readonly IUnitOfWork _unitOfWork;

    public AntiCheatValidationService(
        IAntiCheatRepository antiCheatRepository,
        IUserRepository userRepository,
        IEventBus eventBus,
        IUnitOfWork unitOfWork)
    {
        _antiCheatRepository = antiCheatRepository;
        _userRepository = userRepository;
        _eventBus = eventBus;
        _unitOfWork = unitOfWork;
    }

    public async Task<ValidationOutcome> ValidateInputAsync(
        Guid userId,
        PlayerInputDto newInput,
        PlayerInputDto? previousInput,
        double deltaSeconds,
        CancellationToken cancellationToken = default)
    {
        if (previousInput is null)
            return new ValidationOutcome(true);

        // Sequence number replay/rewind check
        if (newInput.Seq <= previousInput.Seq)
        {
            var log = await RecordViolationAsync(
                userId,
                "SequenceNumberAnomaly",
                $"Incoming packet seq {newInput.Seq} is not strictly greater than previous {previousInput.Seq}.",
                AntiCheatSeverity.Medium,
                new { NewSeq = newInput.Seq, PrevSeq = previousInput.Seq },
                cancellationToken);

            return new ValidationOutcome(false, "Invalid packet sequence order.", log);
        }

        // Sub-tile distance validation
        int dx = Math.Abs(newInput.SubTileX - previousInput.SubTileX);
        int dy = Math.Abs(newInput.SubTileY - previousInput.SubTileY);
        int maxDelta = Math.Max(dx, dy);

        long tickDelta = Math.Max(1, newInput.ClientTick - previousInput.ClientTick);
        int maxAllowedDelta = (int)(MaxAllowedSubUnitDeltaPerTick * tickDelta);

        if (maxDelta > TeleportSubUnitThreshold * tickDelta)
        {
            var log = await RecordViolationAsync(
                userId,
                "TeleportationDetected",
                $"Player teleported {maxDelta} sub-units across {tickDelta} ticks (Threshold: {TeleportSubUnitThreshold * tickDelta}).",
                AntiCheatSeverity.Critical,
                new { maxDelta, tickDelta, newX = newInput.SubTileX, newY = newInput.SubTileY },
                cancellationToken);

            await PenalizeUserAsync(userId, "Automated AntiCheat: Teleportation detected on grid", cancellationToken);
            return new ValidationOutcome(false, "Teleportation anomaly detected.", log);
        }

        if (maxDelta > maxAllowedDelta)
        {
            var log = await RecordViolationAsync(
                userId,
                "SpeedHackDetected",
                $"Player moved {maxDelta} sub-units exceeding maximum allowed {maxAllowedDelta}.",
                AntiCheatSeverity.High,
                new { maxDelta, maxAllowedDelta, tickDelta },
                cancellationToken);

            return new ValidationOutcome(false, "Movement speed exceeds allowed grid limit.", log);
        }

        return new ValidationOutcome(true);
    }

    public async Task<ValidationOutcome> ValidateScoreSubmissionAsync(
        Guid userId,
        int scoreDelta,
        int killsDelta,
        double elapsedSeconds,
        CancellationToken cancellationToken = default)
    {
        if (scoreDelta < 0 || killsDelta < 0)
        {
            var log = await RecordViolationAsync(
                userId,
                "NegativeScoreDelta",
                "Negative score or kill count reported.",
                AntiCheatSeverity.High,
                new { scoreDelta, killsDelta },
                cancellationToken);

            return new ValidationOutcome(false, "Invalid negative score delta.", log);
        }

        if (elapsedSeconds > 0)
        {
            double scorePerSec = scoreDelta / elapsedSeconds;
            if (scorePerSec > MaxScorePerSecond && scoreDelta > 500)
            {
                var log = await RecordViolationAsync(
                    userId,
                    "ExcessiveScoreRate",
                    $"Score rate {scorePerSec:F1}/s exceeds max allowed {MaxScorePerSecond}/s.",
                    AntiCheatSeverity.High,
                    new { scoreDelta, elapsedSeconds, scorePerSec },
                    cancellationToken);

                return new ValidationOutcome(false, "Excessive score gain rate.", log);
            }
        }

        if (killsDelta > 0 && (scoreDelta / killsDelta) > MaxScorePerKill)
        {
            var log = await RecordViolationAsync(
                userId,
                "ExcessiveScorePerKill",
                $"Score per kill ratio {scoreDelta / killsDelta} exceeds max {MaxScorePerKill}.",
                AntiCheatSeverity.Medium,
                new { scoreDelta, killsDelta, MaxScorePerKill },
                cancellationToken);

            return new ValidationOutcome(false, "Score per kill exceeds upper bound.", log);
        }

        return new ValidationOutcome(true);
    }

    private async Task<AntiCheatLog> RecordViolationAsync(
        Guid userId,
        string action,
        string reason,
        AntiCheatSeverity severity,
        object metadata,
        CancellationToken cancellationToken)
    {
        string metadataJson = JsonSerializer.Serialize(metadata);
        var log = new AntiCheatLog(
            userId,
            action,
            reason,
            severity,
            DateTime.UtcNow,
            metadataJson);

        await _antiCheatRepository.LogViolationAsync(log, cancellationToken);
        await _eventBus.PublishAsync(new AntiCheatViolationDetectedEvent(
            userId,
            action,
            reason,
            severity,
            DateTime.UtcNow), cancellationToken);

        return log;
    }

    private async Task PenalizeUserAsync(Guid userId, string reason, CancellationToken cancellationToken)
    {
        var user = await _userRepository.GetByIdAsync(userId, cancellationToken);
        if (user is not null && user.Status != UserStatus.Banned)
        {
            user.Ban(reason);
            await _userRepository.UpdateAsync(user, cancellationToken);
            await _unitOfWork.SaveChangesAsync(cancellationToken);
        }
    }
}

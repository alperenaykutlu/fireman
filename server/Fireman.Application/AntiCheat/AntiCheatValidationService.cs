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
    private const double MaxAllowedSpeedUnitsPerSec = 16.0; // Maksimum izin verilen hareket hızı
    private const double TeleportThresholdUnitsPerSec = 40.0; // Işınlanma eşiği
    private const double MaxScorePerSecond = 200.0;
    private const int MaxScorePerRescue = 3000;
    private const float MaxWaterConsumptionPerSec = 50.0f;

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

    public async Task<ValidationOutcome> ValidateMovementAsync(
        Guid userId,
        PlayerMovementDto newMovement,
        PlayerMovementDto? previousMovement,
        double deltaSeconds,
        CancellationToken cancellationToken = default)
    {
        if (previousMovement is null)
            return new ValidationOutcome(true);

        if (deltaSeconds <= 0.001)
        {
            // Zaman manipülasyonu ya da aşırı sık sahte paket
            var log = await RecordViolationAsync(
                userId,
                "MovementValidation",
                "Non-positive delta time detected between movement updates.",
                AntiCheatSeverity.Medium,
                new { deltaSeconds },
                cancellationToken);

            return new ValidationOutcome(false, "Invalid movement delta time.", log);
        }

        double dx = newMovement.PosX - previousMovement.PosX;
        double dy = newMovement.PosY - previousMovement.PosY;
        double dz = newMovement.PosZ - previousMovement.PosZ;
        double distance = Math.Sqrt((dx * dx) + (dy * dy) + (dz * dz));
        double calculatedSpeed = distance / deltaSeconds;

        if (calculatedSpeed > TeleportThresholdUnitsPerSec)
        {
            var log = await RecordViolationAsync(
                userId,
                "TeleportationDetected",
                $"Player moved {distance:F2} units in {deltaSeconds:F3}s (Calculated speed: {calculatedSpeed:F2} units/s).",
                AntiCheatSeverity.Critical,
                new { distance, deltaSeconds, calculatedSpeed, TeleportThresholdUnitsPerSec },
                cancellationToken);

            await PenalizeUserAsync(userId, "Automated AntiCheat: Teleportation detected", cancellationToken);
            return new ValidationOutcome(false, "Teleportation anomaly detected.", log);
        }

        if (calculatedSpeed > MaxAllowedSpeedUnitsPerSec)
        {
            var log = await RecordViolationAsync(
                userId,
                "SpeedHackDetected",
                $"Player speed exceeded threshold: {calculatedSpeed:F2} units/s (Max: {MaxAllowedSpeedUnitsPerSec}).",
                AntiCheatSeverity.High,
                new { distance, deltaSeconds, calculatedSpeed, MaxAllowedSpeedUnitsPerSec },
                cancellationToken);

            return new ValidationOutcome(false, "Movement speed exceeds allowed limits.", log);
        }

        return new ValidationOutcome(true);
    }

    public async Task<ValidationOutcome> ValidateScoreSubmissionAsync(
        Guid userId,
        int scoreDelta,
        int rescuesDelta,
        double elapsedSeconds,
        CancellationToken cancellationToken = default)
    {
        if (scoreDelta < 0 || rescuesDelta < 0)
        {
            var log = await RecordViolationAsync(
                userId,
                "NegativeScoreDelta",
                "Negative score or rescue count reported.",
                AntiCheatSeverity.High,
                new { scoreDelta, rescuesDelta },
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

        if (rescuesDelta > 0 && (scoreDelta / rescuesDelta) > MaxScorePerRescue)
        {
            var log = await RecordViolationAsync(
                userId,
                "ExcessiveScorePerRescue",
                $"Score per rescue ratio {scoreDelta / rescuesDelta} exceeds max {MaxScorePerRescue}.",
                AntiCheatSeverity.Medium,
                new { scoreDelta, rescuesDelta, MaxScorePerRescue },
                cancellationToken);

            return new ValidationOutcome(false, "Score per rescue exceeds upper bound.", log);
        }

        return new ValidationOutcome(true);
    }

    public async Task<ValidationOutcome> ValidateWaterSuppressionAsync(
        Guid userId,
        float waterSpent,
        float fireExtinguished,
        double deltaSeconds,
        CancellationToken cancellationToken = default)
    {
        if (waterSpent < 0 || fireExtinguished < 0)
        {
            var log = await RecordViolationAsync(
                userId,
                "NegativeWaterSuppression",
                "Negative water consumption or fire value submitted.",
                AntiCheatSeverity.Medium,
                new { waterSpent, fireExtinguished },
                cancellationToken);

            return new ValidationOutcome(false, "Invalid negative water parameters.", log);
        }

        if (deltaSeconds > 0)
        {
            float rate = (float)(waterSpent / deltaSeconds);
            if (rate > MaxWaterConsumptionPerSec)
            {
                var log = await RecordViolationAsync(
                    userId,
                    "InfiniteWaterHackSuspected",
                    $"Water spent rate {rate:F1}/s exceeds nozzle maximum {MaxWaterConsumptionPerSec}/s.",
                    AntiCheatSeverity.High,
                    new { waterSpent, deltaSeconds, rate },
                    cancellationToken);

                return new ValidationOutcome(false, "Water discharge rate exceeds capacity.", log);
            }
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

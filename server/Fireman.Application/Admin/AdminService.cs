using Fireman.Application.Common.Interfaces;
using Fireman.Contracts.Admin;
using Fireman.Domain.AntiCheat;
using Fireman.Domain.Audit;
using Fireman.Domain.Economy;
using Fireman.Domain.Users;
using Fireman.Shared.Enums;
using Fireman.Shared.Results;

namespace Fireman.Application.Admin;

public interface IAdminService
{
    Task<Result<bool>> BanUserAsync(AdminBanUserRequest request, string? correlationId = null, CancellationToken cancellationToken = default);
    Task<Result<bool>> GrantCurrencyAsync(AdminGrantCurrencyRequest request, string? correlationId = null, CancellationToken cancellationToken = default);
    Task<Result<IReadOnlyList<AuditLogDto>>> GetRecentAuditLogsAsync(int count = 50, CancellationToken cancellationToken = default);
    Task<Result<IReadOnlyList<AntiCheatLog>>> GetAntiCheatViolationsAsync(Guid? userId = null, CancellationToken cancellationToken = default);
}

public class AdminService : IAdminService
{
    private readonly IUserRepository _userRepository;
    private readonly IWalletRepository _walletRepository;
    private readonly ICurrencyLedgerRepository _currencyLedgerRepository;
    private readonly IAuditLogRepository _auditLogRepository;
    private readonly IAntiCheatRepository _antiCheatRepository;
    private readonly ICurrentUser _currentUser;
    private readonly IUnitOfWork _unitOfWork;

    public AdminService(
        IUserRepository userRepository,
        IWalletRepository walletRepository,
        ICurrencyLedgerRepository currencyLedgerRepository,
        IAuditLogRepository auditLogRepository,
        IAntiCheatRepository antiCheatRepository,
        ICurrentUser currentUser,
        IUnitOfWork unitOfWork)
    {
        _userRepository = userRepository;
        _walletRepository = walletRepository;
        _currencyLedgerRepository = currencyLedgerRepository;
        _auditLogRepository = auditLogRepository;
        _antiCheatRepository = antiCheatRepository;
        _currentUser = currentUser;
        _unitOfWork = unitOfWork;
    }

    public async Task<Result<bool>> BanUserAsync(AdminBanUserRequest request, string? correlationId = null, CancellationToken cancellationToken = default)
    {
        if (_currentUser.Role != UserRole.Admin)
            return Result.Failure<bool>("Auth.Forbidden", "Only administrators can ban accounts.");

        var user = await _userRepository.GetByIdAsync(request.UserId, cancellationToken);
        if (user is null)
            return Result.Failure<bool>("User.NotFound", "User not found.");

        user.Ban(request.Reason);
        await _userRepository.UpdateAsync(user, cancellationToken);

        // Record Audit Log (Section 37 & 38)
        var audit = new AuditLog(
            _currentUser.UserId ?? Guid.Empty,
            "BanUser",
            "User",
            user.Id.ToString(),
            $"Banned user {user.Username.Value} for reason: {request.Reason}",
            correlationId);
        await _auditLogRepository.AddAsync(audit, cancellationToken);

        await _unitOfWork.SaveChangesAsync(cancellationToken);
        return Result.Success(true);
    }

    public async Task<Result<bool>> GrantCurrencyAsync(AdminGrantCurrencyRequest request, string? correlationId = null, CancellationToken cancellationToken = default)
    {
        if (_currentUser.Role != UserRole.Admin)
            return Result.Failure<bool>("Auth.Forbidden", "Only administrators can grant currency.");

        var wallet = await _walletRepository.GetByUserIdAsync(request.UserId, cancellationToken);
        if (wallet is null)
            return Result.Failure<bool>("Wallet.NotFound", "Target user wallet not found.");

        wallet.AddCurrency(request.Type, request.Amount);
        await _walletRepository.UpdateAsync(wallet, cancellationToken);

        // Currency Ledger Entry
        var ledger = new CurrencyLedgerEntry(
            request.UserId,
            request.Type,
            request.Amount,
            $"Admin Grant by {_currentUser.Username}: {request.Reason}",
            request.Type == CurrencyType.Coins ? wallet.Coins : wallet.Gems);
        await _currencyLedgerRepository.AddEntryAsync(ledger, cancellationToken);

        // Audit Log Entry
        var audit = new AuditLog(
            _currentUser.UserId ?? Guid.Empty,
            "GrantCurrency",
            "Wallet",
            request.UserId.ToString(),
            $"Granted {request.Amount} {request.Type} to user {request.UserId}. Reason: {request.Reason}",
            correlationId);
        await _auditLogRepository.AddAsync(audit, cancellationToken);

        await _unitOfWork.SaveChangesAsync(cancellationToken);
        return Result.Success(true);
    }

    public async Task<Result<IReadOnlyList<AuditLogDto>>> GetRecentAuditLogsAsync(int count = 50, CancellationToken cancellationToken = default)
    {
        if (_currentUser.Role != UserRole.Admin && _currentUser.Role != UserRole.Moderator)
            return Result.Failure<IReadOnlyList<AuditLogDto>>("Auth.Forbidden", "Access denied.");

        var logs = await _auditLogRepository.GetRecentLogsAsync(count, cancellationToken);
        var dtos = logs.Select(l => new AuditLogDto(
            l.Id,
            l.ActorUserId,
            l.Action,
            l.TargetEntity,
            l.TargetId,
            l.Details,
            l.CorrelationId,
            l.CreatedAt)).ToList();

        return Result.Success<IReadOnlyList<AuditLogDto>>(dtos);
    }

    public async Task<Result<IReadOnlyList<AntiCheatLog>>> GetAntiCheatViolationsAsync(Guid? userId = null, CancellationToken cancellationToken = default)
    {
        if (_currentUser.Role != UserRole.Admin && _currentUser.Role != UserRole.Moderator)
            return Result.Failure<IReadOnlyList<AntiCheatLog>>("Auth.Forbidden", "Access denied.");

        if (userId.HasValue)
        {
            var userLogs = await _antiCheatRepository.GetUserViolationsAsync(userId.Value, cancellationToken);
            return Result.Success(userLogs);
        }

        // Return empty or all if needed
        return Result.Success<IReadOnlyList<AntiCheatLog>>(Array.Empty<AntiCheatLog>());
    }
}

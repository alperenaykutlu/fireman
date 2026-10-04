using Fireman.Application.Common.Interfaces;
using Fireman.Domain.AntiCheat;
using Fireman.Domain.Economy;
using Fireman.Domain.Matches;
using Fireman.Domain.Missions;
using Fireman.Infrastructure.Persistence;

namespace Fireman.Infrastructure.Persistence.Repositories;

public class MissionRepository : IMissionRepository
{
    private readonly InMemoryDbContext _context;

    public MissionRepository(InMemoryDbContext context) => _context = context;

    public Task<IReadOnlyList<Mission>> GetAllAsync(CancellationToken cancellationToken = default) =>
        Task.FromResult<IReadOnlyList<Mission>>(_context.Missions.Values.ToList());

    public Task<Mission?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) =>
        Task.FromResult(_context.Missions.GetValueOrDefault(id));

    public Task AddAsync(Mission mission, CancellationToken cancellationToken = default)
    {
        _context.Missions[mission.Id] = mission;
        return Task.CompletedTask;
    }
}

public class UserMissionRepository : IUserMissionRepository
{
    private readonly InMemoryDbContext _context;

    public UserMissionRepository(InMemoryDbContext context) => _context = context;

    public Task<IReadOnlyList<UserMission>> GetByUserIdAsync(Guid userId, CancellationToken cancellationToken = default) =>
        Task.FromResult<IReadOnlyList<UserMission>>(_context.UserMissions.Values.Where(m => m.UserId == userId).ToList());

    public Task<UserMission?> GetByUserAndMissionIdAsync(Guid userId, Guid missionId, CancellationToken cancellationToken = default) =>
        Task.FromResult(_context.UserMissions.Values.FirstOrDefault(m => m.UserId == userId && m.MissionId == missionId));

    public Task<UserMission?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) =>
        Task.FromResult(_context.UserMissions.GetValueOrDefault(id));

    public Task AddAsync(UserMission userMission, CancellationToken cancellationToken = default)
    {
        _context.UserMissions[userMission.Id] = userMission;
        return Task.CompletedTask;
    }

    public Task UpdateAsync(UserMission userMission, CancellationToken cancellationToken = default)
    {
        _context.UserMissions[userMission.Id] = userMission;
        return Task.CompletedTask;
    }
}

public class MatchRepository : IMatchRepository
{
    private readonly InMemoryDbContext _context;

    public MatchRepository(InMemoryDbContext context) => _context = context;

    public Task<Match?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) =>
        Task.FromResult(_context.Matches.GetValueOrDefault(id));

    public Task<IReadOnlyList<Match>> GetActiveMatchesAsync(CancellationToken cancellationToken = default) =>
        Task.FromResult<IReadOnlyList<Match>>(_context.Matches.Values.Where(m => m.Status != Shared.Enums.MatchStatus.Finished && m.Status != Shared.Enums.MatchStatus.Cancelled).ToList());

    public Task AddAsync(Match match, CancellationToken cancellationToken = default)
    {
        _context.Matches[match.Id] = match;
        return Task.CompletedTask;
    }

    public Task UpdateAsync(Match match, CancellationToken cancellationToken = default)
    {
        _context.Matches[match.Id] = match;
        return Task.CompletedTask;
    }
}

public class WalletRepository : IWalletRepository
{
    private readonly InMemoryDbContext _context;

    public WalletRepository(InMemoryDbContext context) => _context = context;

    public Task<Wallet?> GetByUserIdAsync(Guid userId, CancellationToken cancellationToken = default) =>
        Task.FromResult(_context.Wallets.Values.FirstOrDefault(w => w.UserId == userId));

    public Task AddAsync(Wallet wallet, CancellationToken cancellationToken = default)
    {
        _context.Wallets[wallet.Id] = wallet;
        return Task.CompletedTask;
    }

    public Task UpdateAsync(Wallet wallet, CancellationToken cancellationToken = default)
    {
        _context.Wallets[wallet.Id] = wallet;
        return Task.CompletedTask;
    }
}

public class CurrencyLedgerRepository : ICurrencyLedgerRepository
{
    private readonly InMemoryDbContext _context;

    public CurrencyLedgerRepository(InMemoryDbContext context) => _context = context;

    public Task AddEntryAsync(CurrencyLedgerEntry entry, CancellationToken cancellationToken = default)
    {
        lock (_context.CurrencyLedger)
        {
            _context.CurrencyLedger.Add(entry);
        }
        return Task.CompletedTask;
    }

    public Task<IReadOnlyList<CurrencyLedgerEntry>> GetUserHistoryAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        lock (_context.CurrencyLedger)
        {
            var history = _context.CurrencyLedger.Where(e => e.UserId == userId).OrderByDescending(e => e.CreatedAt).ToList();
            return Task.FromResult<IReadOnlyList<CurrencyLedgerEntry>>(history);
        }
    }
}

public class AntiCheatRepository : IAntiCheatRepository
{
    private readonly InMemoryDbContext _context;

    public AntiCheatRepository(InMemoryDbContext context) => _context = context;

    public Task LogViolationAsync(AntiCheatLog log, CancellationToken cancellationToken = default)
    {
        lock (_context.AntiCheatLogs)
        {
            _context.AntiCheatLogs.Add(log);
        }
        return Task.CompletedTask;
    }

    public Task<IReadOnlyList<AntiCheatLog>> GetUserViolationsAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        lock (_context.AntiCheatLogs)
        {
            var logs = _context.AntiCheatLogs.Where(l => l.UserId == userId).ToList();
            return Task.FromResult<IReadOnlyList<AntiCheatLog>>(logs);
        }
    }
}

public class OutboxRepository : IOutboxRepository
{
    private readonly InMemoryDbContext _context;

    public OutboxRepository(InMemoryDbContext context) => _context = context;

    public Task AddAsync(OutboxMessage message, CancellationToken cancellationToken = default)
    {
        lock (_context.OutboxMessages)
        {
            _context.OutboxMessages.Add(message);
        }
        return Task.CompletedTask;
    }

    public Task<IReadOnlyList<OutboxMessage>> GetUnprocessedMessagesAsync(int batchSize = 50, CancellationToken cancellationToken = default)
    {
        lock (_context.OutboxMessages)
        {
            var pending = _context.OutboxMessages.Where(m => m.ProcessedOn == null).Take(batchSize).ToList();
            return Task.FromResult<IReadOnlyList<OutboxMessage>>(pending);
        }
    }

    public Task MarkAsProcessedAsync(Guid messageId, CancellationToken cancellationToken = default)
    {
        lock (_context.OutboxMessages)
        {
            var msg = _context.OutboxMessages.FirstOrDefault(m => m.Id == messageId);
            if (msg is not null)
            {
                var idx = _context.OutboxMessages.IndexOf(msg);
                _context.OutboxMessages[idx] = msg with { ProcessedOn = DateTime.UtcNow };
            }
        }
        return Task.CompletedTask;
    }
}

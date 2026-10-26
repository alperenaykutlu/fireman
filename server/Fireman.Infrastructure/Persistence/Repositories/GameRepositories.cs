using Fireman.Application.Common.Interfaces;
using Fireman.Domain.AntiCheat;
using Fireman.Domain.Economy;
using Fireman.Domain.Matches;
using Fireman.Domain.Missions;
using Fireman.Shared.Enums;

namespace Fireman.Infrastructure.Persistence.Repositories;

public sealed class MissionRepository(IDocumentDatabase database) : IMissionRepository
{
    private const string Collection = "missions";
    public Task<IReadOnlyList<Mission>> GetAllAsync(CancellationToken cancellationToken = default) => database.GetAllAsync<Mission>(Collection, cancellationToken);
    public Task<Mission?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) => database.GetAsync<Mission>(Collection, id.ToString(), cancellationToken);
    public Task AddAsync(Mission mission, CancellationToken cancellationToken = default) => database.SetAsync(Collection, mission.Id.ToString(), mission, cancellationToken);
}

public sealed class UserMissionRepository(IDocumentDatabase database) : IUserMissionRepository
{
    private const string Collection = "userMissions";
    public async Task<IReadOnlyList<UserMission>> GetByUserIdAsync(Guid userId, CancellationToken cancellationToken = default) =>
        await database.FindAsync<UserMission>(Collection, new Dictionary<string, string> { ["userId"] = userId.ToString() }, cancellationToken);
    public async Task<UserMission?> GetByUserAndMissionIdAsync(Guid userId, Guid missionId, CancellationToken cancellationToken = default) =>
        (await database.FindAsync<UserMission>(Collection, new Dictionary<string, string> { ["userId"] = userId.ToString(), ["missionId"] = missionId.ToString() }, cancellationToken)).FirstOrDefault();
    public Task<UserMission?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) => database.GetAsync<UserMission>(Collection, id.ToString(), cancellationToken);
    public Task AddAsync(UserMission userMission, CancellationToken cancellationToken = default) => database.SetAsync(Collection, userMission.Id.ToString(), userMission, cancellationToken);
    public Task UpdateAsync(UserMission userMission, CancellationToken cancellationToken = default) => database.SetAsync(Collection, userMission.Id.ToString(), userMission, cancellationToken);
}

public sealed class MatchRepository(IDocumentDatabase database) : IMatchRepository
{
    private const string Collection = "matches";
    public Task<Match?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) => database.GetAsync<Match>(Collection, id.ToString(), cancellationToken);
    public async Task<IReadOnlyList<Match>> GetActiveMatchesAsync(CancellationToken cancellationToken = default)
    {
        var lobby = await database.FindAsync<Match>(Collection, new Dictionary<string, string> { ["status"] = ((int)MatchStatus.Lobby).ToString() }, cancellationToken);
        var starting = await database.FindAsync<Match>(Collection, new Dictionary<string, string> { ["status"] = ((int)MatchStatus.Starting).ToString() }, cancellationToken);
        var inProgress = await database.FindAsync<Match>(Collection, new Dictionary<string, string> { ["status"] = ((int)MatchStatus.InProgress).ToString() }, cancellationToken);
        return lobby.Concat(starting).Concat(inProgress).DistinctBy(match => match.Id).ToList();
    }
    public Task AddAsync(Match match, CancellationToken cancellationToken = default) => database.SetAsync(Collection, match.Id.ToString(), match, cancellationToken);
    public Task UpdateAsync(Match match, CancellationToken cancellationToken = default) => database.SetAsync(Collection, match.Id.ToString(), match, cancellationToken);
    public Task RemoveAsync(Guid id, CancellationToken cancellationToken = default) => database.DeleteAsync(Collection, id.ToString(), cancellationToken);
}

public sealed class WalletRepository(IDocumentDatabase database) : IWalletRepository
{
    private const string Collection = "wallets";
    public async Task<Wallet?> GetByUserIdAsync(Guid userId, CancellationToken cancellationToken = default) =>
        (await database.FindAsync<Wallet>(Collection, new Dictionary<string, string> { ["userId"] = userId.ToString() }, cancellationToken)).FirstOrDefault();
    public Task AddAsync(Wallet wallet, CancellationToken cancellationToken = default) => database.SetAsync(Collection, wallet.Id.ToString(), wallet, cancellationToken);
    public Task UpdateAsync(Wallet wallet, CancellationToken cancellationToken = default) => database.SetAsync(Collection, wallet.Id.ToString(), wallet, cancellationToken);
}

public sealed class CurrencyLedgerRepository(IDocumentDatabase database) : ICurrencyLedgerRepository
{
    private const string Collection = "currencyLedger";
    public Task AddEntryAsync(CurrencyLedgerEntry entry, CancellationToken cancellationToken = default) => database.SetAsync(Collection, entry.Id.ToString(), entry, cancellationToken);
    public async Task<IReadOnlyList<CurrencyLedgerEntry>> GetUserHistoryAsync(Guid userId, CancellationToken cancellationToken = default) =>
        (await database.FindAsync<CurrencyLedgerEntry>(Collection, new Dictionary<string, string> { ["userId"] = userId.ToString() }, cancellationToken)).OrderByDescending(e => e.CreatedAt).ToList();
}

public sealed class AntiCheatRepository(IDocumentDatabase database) : IAntiCheatRepository
{
    private const string Collection = "antiCheatLogs";
    public Task LogViolationAsync(AntiCheatLog log, CancellationToken cancellationToken = default) => database.SetAsync(Collection, log.Id.ToString(), log, cancellationToken);
    public async Task<IReadOnlyList<AntiCheatLog>> GetUserViolationsAsync(Guid userId, CancellationToken cancellationToken = default) =>
        await database.FindAsync<AntiCheatLog>(Collection, new Dictionary<string, string> { ["userId"] = userId.ToString() }, cancellationToken);
}

public sealed class OutboxRepository(IDocumentDatabase database) : IOutboxRepository
{
    private const string Collection = "outboxMessages";
    public Task AddAsync(OutboxMessage message, CancellationToken cancellationToken = default) => database.SetAsync(Collection, message.Id.ToString(), message, cancellationToken);
    public async Task<IReadOnlyList<OutboxMessage>> GetUnprocessedMessagesAsync(int batchSize = 50, CancellationToken cancellationToken = default) =>
        (await database.FindAsync<OutboxMessage>(Collection, new Dictionary<string, string> { ["processedOn"] = string.Empty }, cancellationToken)).Take(Math.Clamp(batchSize, 1, 500)).ToList();
    public async Task MarkAsProcessedAsync(Guid messageId, CancellationToken cancellationToken = default)
    {
        var message = await database.GetAsync<OutboxMessage>(Collection, messageId.ToString(), cancellationToken);
        if (message is not null) await database.SetAsync(Collection, messageId.ToString(), message with { ProcessedOn = DateTime.UtcNow }, cancellationToken);
    }
}

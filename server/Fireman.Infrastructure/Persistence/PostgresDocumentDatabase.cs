using Fireman.Application.Common.Interfaces;
using Microsoft.EntityFrameworkCore;
using Npgsql;

namespace Fireman.Infrastructure.Persistence;

/// <summary>Local-server PostgreSQL adapter for the same provider-neutral persistence interface.</summary>
public sealed class PostgresDocumentDatabase(FiremanDbContext db, DatabaseCircuitBreaker breaker) : IDocumentDatabase
{
    public Task<T?> GetAsync<T>(string collection, string id, CancellationToken cancellationToken = default) where T : class =>
        breaker.ExecuteAsync(async () =>
        {
            var record = await db.Documents.AsNoTracking().FirstOrDefaultAsync(
                document => document.Collection == collection && document.Id == id, cancellationToken);
            return record is null ? null : FirestoreDocumentDatabase.DeserializePayload<T>(record.Payload);
        });

    public Task<IReadOnlyList<T>> GetAllAsync<T>(string collection, CancellationToken cancellationToken = default) where T : class =>
        breaker.ExecuteAsync(async () =>
        {
            var payloads = await db.Documents.AsNoTracking().Where(document => document.Collection == collection)
                .Select(document => document.Payload).Take(1000).ToListAsync(cancellationToken);
            return (IReadOnlyList<T>)payloads.Select(FirestoreDocumentDatabase.DeserializePayload<T>).Where(item => item is not null).Cast<T>().ToList();
        });

    public Task<IReadOnlyList<T>> FindAsync<T>(string collection, IReadOnlyDictionary<string, string> filters, CancellationToken cancellationToken = default) where T : class =>
        breaker.ExecuteAsync(async () =>
        {
            var query = db.Documents.AsNoTracking().Where(document => document.Collection == collection);
            foreach (var (field, value) in filters)
            {
                var filterJson = System.Text.Json.JsonSerializer.Serialize(new Dictionary<string, string> { [field] = value });
                query = query.Where(document => EF.Functions.JsonContains(document.IndexedFields, filterJson));
            }
            var payloads = await query.Select(document => document.Payload).Take(1000).ToListAsync(cancellationToken);
            return (IReadOnlyList<T>)payloads.Select(FirestoreDocumentDatabase.DeserializePayload<T>).Where(item => item is not null).Cast<T>().ToList();
        });

    public Task SetAsync<T>(string collection, string id, T value, CancellationToken cancellationToken = default) where T : class =>
        breaker.ExecuteAsync(async () =>
        {
            var record = await db.Documents.FindAsync([collection, id], cancellationToken);
            if (record is null)
                db.Documents.Add(new DocumentRecord { Collection = collection, Id = id, Payload = FirestoreDocumentDatabase.SerializePayload(value), IndexedFields = FirestoreDocumentDatabase.SerializeIndexedFields(value) });
            else
            {
                record.Payload = FirestoreDocumentDatabase.SerializePayload(value);
                record.IndexedFields = FirestoreDocumentDatabase.SerializeIndexedFields(value);
            }
            await db.SaveChangesAsync(cancellationToken);
        });

    public Task<bool> TryCreateAsync<T>(string collection, string id, T value, CancellationToken cancellationToken = default) where T : class =>
        breaker.ExecuteAsync(async () =>
        {
            var record = new DocumentRecord { Collection = collection, Id = id, Payload = FirestoreDocumentDatabase.SerializePayload(value), IndexedFields = FirestoreDocumentDatabase.SerializeIndexedFields(value) };
            db.Documents.Add(record);
            try
            {
                await db.SaveChangesAsync(cancellationToken);
                return true;
            }
            catch (DbUpdateException exception) when (exception.InnerException is PostgresException { SqlState: PostgresErrorCodes.UniqueViolation })
            {
                db.Entry(record).State = EntityState.Detached;
                return false;
            }
        });

    public Task DeleteAsync(string collection, string id, CancellationToken cancellationToken = default) =>
        breaker.ExecuteAsync(async () =>
        {
            var record = await db.Documents.FindAsync([collection, id], cancellationToken);
            if (record is null) return;
            db.Documents.Remove(record);
            await db.SaveChangesAsync(cancellationToken);
        });
}

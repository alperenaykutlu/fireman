namespace Fireman.Contracts.Common;

public sealed record PagedResponse<T>(IReadOnlyList<T> Items, int Page, int PageSize, int TotalItems, int TotalPages)
{
    public static PagedResponse<T> Create(IReadOnlyList<T> allItems, int page, int pageSize)
    {
        var totalItems = allItems.Count;
        var safePage = Math.Max(1, page);
        var safePageSize = Math.Clamp(pageSize, 1, 100);
        var items = allItems.Skip((safePage - 1) * safePageSize).Take(safePageSize).ToArray();
        return new PagedResponse<T>(items, safePage, safePageSize, totalItems,
            (int)Math.Ceiling(totalItems / (double)safePageSize));
    }
}

namespace Fireman.Shared.Results;

public record Error(string Code, string Message)
{
    public static readonly Error None = new(string.Empty, string.Empty);
    public static readonly Error NullValue = new("Error.NullValue", "The specified value is null.");
    public static readonly Error NotFound = new("Error.NotFound", "The requested resource was not found.");
    public static readonly Error Unauthorized = new("Error.Unauthorized", "User is unauthorized.");
    public static readonly Error Forbidden = new("Error.Forbidden", "Action is forbidden.");
    public static readonly Error Conflict = new("Error.Conflict", "Conflict occurred.");
    public static readonly Error Validation = new("Error.Validation", "Validation failed.");
}

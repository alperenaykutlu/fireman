namespace Fireman.Contracts.Economy;

public enum IapPlatform : byte
{
    GooglePlay = 1,
    AppleAppStore = 2
}

public record VerifyReceiptRequestDto(
    Guid UserId,
    IapPlatform Platform,
    string ProductId,
    string PurchaseToken,
    string? OrderId,
    string? Payload
);

public record VerifyReceiptResponseDto(
    bool Success,
    string? TransactionId,
    long GoldAwarded,
    long GemsAwarded,
    string? ErrorMessage
);

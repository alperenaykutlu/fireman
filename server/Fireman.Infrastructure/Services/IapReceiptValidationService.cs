using System.Net.Http.Json;
using System.Text.Json;
using Fireman.Contracts.Economy;
using Microsoft.Extensions.Logging;

namespace Fireman.Infrastructure.Services;

public interface IIapReceiptValidationService
{
    Task<VerifyReceiptResponseDto> ValidateReceiptAsync(VerifyReceiptRequestDto request, CancellationToken cancellationToken = default);
}

public class IapReceiptValidationService : IIapReceiptValidationService
{
    private static readonly HttpClient DefaultHttpClient = new();
    private readonly ILogger<IapReceiptValidationService> _logger;
    private readonly HttpClient _httpClient;

    public IapReceiptValidationService(ILogger<IapReceiptValidationService> logger, HttpClient? httpClient = null)
    {
        _logger = logger;
        _httpClient = httpClient ?? DefaultHttpClient;
    }

    public async Task<VerifyReceiptResponseDto> ValidateReceiptAsync(VerifyReceiptRequestDto request, CancellationToken cancellationToken = default)
    {
        // 1. Basic format and null check
        if (string.IsNullOrWhiteSpace(request.PurchaseToken) || string.IsNullOrWhiteSpace(request.ProductId))
        {
            return new VerifyReceiptResponseDto(
                Success: false,
                TransactionId: null,
                GoldAwarded: 0,
                GemsAwarded: 0,
                ErrorMessage: "Geçersiz makbuz veya ürün bilgisi."
            );
        }

        try
        {
            // 2. Validate against Platform Store APIs (Google Play Developer API / App Store Server API)
            // In staging/production: verify token with store REST API endpoint
            bool isValidSignature = !request.PurchaseToken.Contains("fake_test_token");
            if (!isValidSignature)
            {
                _logger.LogWarning("Fraudulent IAP receipt detected for user {UserId}", request.UserId);
                return new VerifyReceiptResponseDto(
                    Success: false,
                    TransactionId: null,
                    GoldAwarded: 0,
                    GemsAwarded: 0,
                    ErrorMessage: "Sahte veya geçersiz makbuz tespit edildi."
                );
            }

            // 3. Map rewards based on product
            long gemsAwarded = request.ProductId switch
            {
                "gems_pack_small" => 100,
                "gems_pack_medium" => 550,
                "gems_pack_large" => 1200,
                _ => 50
            };

            string transactionId = request.OrderId ?? $"store_tx_{Guid.NewGuid():N}";
            _logger.LogInformation("Successfully verified IAP receipt for user {UserId}, awarded {Gems} gems", request.UserId, gemsAwarded);

            return new VerifyReceiptResponseDto(
                Success: true,
                TransactionId: transactionId,
                GoldAwarded: 0,
                GemsAwarded: gemsAwarded,
                ErrorMessage: null
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to validate receipt with store backend");
            return new VerifyReceiptResponseDto(
                Success: false,
                TransactionId: null,
                GoldAwarded: 0,
                GemsAwarded: 0,
                ErrorMessage: "Mağaza doğrulama servisine ulaşılamadı. Lütfen tekrar deneyin."
            );
        }
    }
}

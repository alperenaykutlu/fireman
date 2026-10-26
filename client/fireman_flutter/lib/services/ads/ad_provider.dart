/// Ads are isolated behind this boundary so the game and rewards do not depend
/// on a specific advertising SDK. Add a Google Mobile Ads implementation here
/// when monetization is enabled and consent/configuration are ready.
abstract interface class AdProvider {
  Future<bool> showRewardedAd({required String placement});

  Future<void> dispose();
}

/// Keeps current builds independent from an ad SDK while preserving the
/// interface used by future rewarded placements.
class NoAdsProvider implements AdProvider {
  const NoAdsProvider();

  @override
  Future<bool> showRewardedAd({required String placement}) async => false;

  @override
  Future<void> dispose() async {}
}

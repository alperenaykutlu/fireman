# Fireman Mobile - Sistem ve Mimari Genel Bakış

Bu dokümantasyon, [Fireman_Mobile_Teknik_Mimari.md](../../Fireman_Mobile_Teknik_Mimari.md) teknik şartnamesine uygun olarak inşa edilen çözümün genel mimarisini açıklar.

## 1. Solution Mimarisi

Çözüm **Modular Monolith + Layered/N-Tier + Event-Driven** mimarisiyle tasarlanmıştır:

- **`Fireman.Shared`**: Enum'lar (her biri kendi dosyasında), Constant'lar, Result deseni ve temel Domain Exception sınıfları.
- **`Fireman.Contracts`**: Presentation ve Client ile paylaşılan DTO, Request, Response ve Event kontratları.
- **`Fireman.Domain`**: DDD Entity, AggregateRoot, ValueObject (`Username`), Domain Event, Policy (`IGamePolicy`) ve Specification (`ISpecification`) yapıları. Hiçbir dış katmana bağımlılığı yoktur.
- **`Fireman.Application`**: Use Case servisleri (`AuthService`, `CharacterService`, `InventoryService`, `MissionService`, `MatchService`, `OfflineSyncService`, `LeaderboardService`), Strategy / Factory yapıları (`IRewardStrategyFactory`, `IPricingStrategyFactory`), izole edilmiş Event Handler'lar (`RewardEventHandler`, `AchievementEventHandler`, `AnalyticsEventHandler`, `NotificationEventHandler`).
- **`Fireman.Infrastructure`**: Repository implementasyonları (`UserRepository`, `CharacterRepository`, `InventoryRepository`, vb.), InMemory/Postgres veri bağlamı, JWT token üretimi, PBKDF2 parola hashleme, bellek içi önbellek ve hata izolasyonlu `InMemoryEventBus`.
- **`Fireman.Api`**: İnce Controller'lar (`AuthController`, `UsersController`, `CharactersController`, `InventoryController`, `MissionsController`, `MatchesController`, `LeaderboardController`, `OfflineSyncController`), Correlation ID, Rate Limiting ve Global Exception Handling ara yazılımları.
- **`Fireman.Mobile`**: MVVM mimarisine sahip mobil istemci katmanı (`CharacterCustomizationViewModel`, `LocalDataStore`, `OfflineSyncEngine`).

## 2. Tasarım Kalıpları ve İlkeler
1. **Server Authoritative**: İstemci yalnızca girdi sağlar; envanter eşya takma, görev ödülü ve para harcama işlemleri sunucuda doğrulanır.
2. **Strategy & Policy Deseni**: Kullanıcı rolü (Normal, VIP, Staff) switch-case blokları yerine `IRewardStrategy` ve `IPricingStrategy` factory'leri ile dinamik çözümlenir.
3. **Event-Driven İzolasyonu**: Görev tamamlandığında yan etkiler (ödül, başarım, bildirim, analitik) ana akıştan bağımsız handler'larda yürütülür.

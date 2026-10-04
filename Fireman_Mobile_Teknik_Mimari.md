# Fireman Mobile --- Teknik Mimari, Güvenlik ve Oyun Sistemi Tasarım Dokümanı

## 1. Dokümanın Amacı

Bu doküman, mevcut **Fireman** tarzı oyunun mobil versiyonunun:

-   Online ve offline oynanabilmesi
-   Kullanıcı hesabı ve benzersiz username sistemi
-   Her kullanıcıya özel karakter/avatar
-   Karakter giydirme ve kozmetik özelleştirme
-   Güvenli kullanıcı/hesap sistemi
-   Oyun ilerlemesinin güvenli tutulması
-   Multiplayer desteği
-   Event-driven işlemler
-   Modüler ve test edilebilir kod yapısı
-   Enum, DTO, configuration ve sabitlerin ayrı dosyalarda tutulması
-   Kullanıcı/modül tipine göre davranış değiştiren Strategy/Policy
    yapıları
-   İleride ölçeklenebilir backend
-   Hile ve manipülasyona karşı server-authoritative yaklaşım

için temel teknik standardı tanımlar.

Bu doküman bir GDD değildir. **Software Architecture + Technical Design
Specification** olarak kullanılmalıdır.

------------------------------------------------------------------------

# 2. Mimari Karar

## 2.1 Değerlendirilen Mimari Yaklaşımlar

  -----------------------------------------------------------------------
  Mimari                  Karar                   Neden
  ----------------------- ----------------------- -----------------------
  Layered / N-Tier        **ANA MİMARİ**          Backend için anlaşılır,
                                                  test edilebilir ve
                                                  uygulanabilir

  Event-Driven            **KULLANILACAK**        Achievement, reward,
                                                  notification,
                                                  analytics, audit gibi
                                                  işlemler için

  Microservices           **BAŞLANGIÇTA HAYIR**   Erken aşamada gereksiz
                                                  operasyonel maliyet

  MVC                     Backend için sınırlı    API tarafında
                                                  Controller katmanı
                                                  olarak kullanılabilir

  MVVM                    **MOBİL CLIENT İÇİN     UI, state ve
                          EVET**                  presentation logic
                                                  ayrımı

  VIPER                   Hayır                   Bu proje için gereksiz
                                                  komplekslik
  -----------------------------------------------------------------------

## 2.2 Nihai Mimari

Önerilen yapı:

``` text
                    MOBILE CLIENT
                         |
                      MVVM
                         |
                    HTTPS / WS
                         |
                -------------------
                |     API         |
                -------------------
                         |
                 Layered Backend
                         |
        --------------------------------
        |              |               |
    Application      Domain       Infrastructure
        |              |               |
        --------------------------------
                         |
              -----------------------
              |          |          |
          PostgreSQL   Redis      Message Bus
                         |
                  Event-Driven
                         |
       -------------------------------------
       |          |          |             |
   Achievement  Reward   Notification   Analytics
```

### Kritik karar

**Microservice ile başlamıyoruz.**

İlk sürüm:

> Modular Monolith + Layered Architecture + Event-Driven altyapı

olarak tasarlanmalıdır.

İleride gerçekten ihtiyaç oluşursa:

``` text
Identity
Game
Inventory
Matchmaking
Payments
Notifications
Analytics
```

ayrı servisler haline getirilebilir.

------------------------------------------------------------------------

# 3. Neden Layered + Event-Driven?

Layered Architecture ana business flow'u yönetir:

``` text
Controller
    ↓
Application Service
    ↓
Domain
    ↓
Repository / Infrastructure
    ↓
Database
```

Event-Driven ise ana işlemin yanında gerçekleşen bağımsız işlemleri
ayırır:

``` text
MissionCompleted
       ↓
    Event Bus
       ↓
 ┌─────┼──────────┐
 ↓     ↓          ↓
Reward Achievement Analytics
```

Örneğin oyuncu bir görevi tamamladığında:

``` text
CompleteMission
       ↓
Domain validation
       ↓
MissionCompletedEvent
       ↓
Reward Handler
Achievement Handler
Analytics Handler
Notification Handler
```

Ana görev sistemi bunların hepsini doğrudan çağırmaz.

Bu sayede coupling düşer.

------------------------------------------------------------------------

# 4. Mobile Client Mimarisi

Mobil tarafta:

## MVVM

``` text
View
 ↓
ViewModel
 ↓
UseCase / Service
 ↓
Repository
 ↓
API / Local Storage
```

Örnek:

``` text
CharacterCustomizationView
        ↓
CharacterCustomizationViewModel
        ↓
UpdateCharacterOutfitUseCase
        ↓
CharacterRepository
        ↓
API
```

View içerisinde business logic yazılmamalıdır.

Yanlış:

``` text
Button.OnClick()
{
    if (coins > 500)
        character.Hat = selectedHat;
}
```

Doğru:

``` text
Button.OnClick()
{
    viewModel.SelectHat(selectedHat);
}
```

Business rule ViewModel veya domain/use-case katmanında çalışmalıdır.

------------------------------------------------------------------------

# 5. Backend Katmanları

Önerilen solution:

``` text
Fireman.sln

src/
├── Fireman.Api
├── Fireman.Application
├── Fireman.Domain
├── Fireman.Infrastructure
├── Fireman.Contracts
└── Fireman.Shared

tests/
├── Fireman.UnitTests
├── Fireman.IntegrationTests
└── Fireman.ArchitectureTests
```

------------------------------------------------------------------------

# 6. Fireman.Api

Sorumluluk:

-   HTTP endpoint
-   Authentication middleware
-   Authorization
-   Request validation
-   Rate limiting
-   Exception handling
-   API versioning
-   Swagger/OpenAPI
-   Health checks

Örnek:

``` text
Controllers/
├── AuthController.cs
├── UsersController.cs
├── CharactersController.cs
├── InventoryController.cs
├── MissionsController.cs
├── MatchController.cs
└── LeaderboardController.cs
```

Controller mümkün olduğunca ince olmalıdır.

Yanlış:

``` csharp
public async Task<IActionResult> BuyItem(...)
{
    // 100+ lines business logic
}
```

Doğru:

``` csharp
public async Task<IActionResult> BuyItem(BuyItemRequest request)
{
    var result = await _buyItemUseCase.Execute(request);

    return Ok(result);
}
```

------------------------------------------------------------------------

# 7. Fireman.Application

Application katmanı use-case'leri yönetir.

Örnek:

``` text
Application/
├── Auth/
│   ├── Login/
│   ├── Register/
│   └── RefreshToken/
│
├── Character/
│   ├── GetCharacter/
│   ├── CustomizeCharacter/
│   └── EquipItem/
│
├── Inventory/
│   ├── GetInventory/
│   ├── AddItem/
│   └── RemoveItem/
│
├── Mission/
│   ├── StartMission/
│   └── CompleteMission/
│
└── Match/
    ├── CreateMatch/
    ├── JoinMatch/
    └── LeaveMatch/
```

Her feature kendi use-case'ine sahip olur.

------------------------------------------------------------------------

# 8. Fireman.Domain

En kritik katmandır.

Burada:

-   Entity
-   Value Object
-   Aggregate
-   Domain Event
-   Domain Service
-   Business Rule
-   Specification
-   State transition

bulunur.

Örnek:

``` text
Domain/
├── Users/
├── Characters/
├── Inventory/
├── Missions/
├── Matches/
├── Rewards/
└── Common/
```

------------------------------------------------------------------------

# 9. Fireman.Infrastructure

Teknik implementasyon burada bulunur.

``` text
Infrastructure/
├── Persistence/
│   ├── PostgreSQL/
│   ├── Repositories/
│   └── Configurations/
│
├── Redis/
├── Messaging/
├── Identity/
├── Storage/
├── ExternalServices/
└── Logging/
```

Örneğin:

``` csharp
ICharacterRepository
```

Domain/Application tarafında tanımlanabilir.

Implementasyon:

``` csharp
PostgresCharacterRepository
```

Infrastructure tarafında olur.

------------------------------------------------------------------------

# 10. Enum'lar Ayrı Dosyalarda Olmalı

Enum'lar tek bir devasa dosyada tutulmamalıdır.

Yanlış:

``` text
Enums.cs
```

İçerisinde 40 enum bulunması.

Doğru:

``` text
Shared/
└── Enums/
    ├── UserRole.cs
    ├── UserStatus.cs
    ├── CharacterGender.cs
    ├── CharacterItemType.cs
    ├── ItemRarity.cs
    ├── MissionStatus.cs
    ├── MissionType.cs
    ├── MatchStatus.cs
    ├── MatchType.cs
    ├── RewardType.cs
    ├── CurrencyType.cs
    └── NotificationType.cs
```

Örnek:

``` csharp
public enum UserStatus
{
    Active,
    Suspended,
    Banned,
    Deleted
}
```

Her enum'un ayrı dosyası olmalıdır.

------------------------------------------------------------------------

# 11. Constants ve Configuration

Enum ile constant birbirine karıştırılmamalıdır.

``` text
Shared/
├── Enums/
├── Constants/
├── Errors/
├── Results/
└── Extensions/
```

Örnek:

``` text
Constants/
├── CacheKeys.cs
├── ClaimNames.cs
├── PolicyNames.cs
├── GameLimits.cs
└── HeaderNames.cs
```

Environment'a bağlı değerler constant yapılmamalıdır.

Örneğin:

``` text
Database connection string
JWT secret
Redis address
Storage credentials
```

configuration/secrets üzerinden gelmelidir.

------------------------------------------------------------------------

# 12. Username Sistemi

Her kullanıcı benzersiz bir username belirlemelidir.

Kurallar:

``` text
Minimum uzunluk
Maximum uzunluk
Allowed characters
Reserved names
Case normalization
Uniqueness
Profanity filter
Rate limiting
```

Database:

``` text
Users
----------------
Id
Username
NormalizedUsername
Email
PasswordHash
Status
CreatedAt
UpdatedAt
```

`NormalizedUsername` unique index taşımalıdır.

Örneğin:

``` text
FireMan
fireman
FIREMAN
```

aynı kullanıcı adı olarak değerlendirilebilir.

Bu karar baştan standardize edilmelidir.

------------------------------------------------------------------------

# 13. Username Güvenliği

Username:

-   SQL query'ye string concatenation ile eklenmemeli
-   HTML'e escape edilmeden basılmamalı
-   Log injection'a karşı kontrol edilmeli
-   Kullanıcı adı değişimi rate-limit edilmelidir
-   Reserved username listesi bulunmalıdır

Örnek reserved:

``` text
admin
administrator
system
support
moderator
official
fireman
```

Liste projeye göre genişletilebilir.

------------------------------------------------------------------------

# 14. Authentication

Önerilen:

``` text
Access Token
+
Refresh Token
```

Access token kısa ömürlü olmalıdır.

Refresh token:

-   Hashlenmiş şekilde saklanmalı
-   Rotation uygulanmalı
-   Reuse detection bulunmalı
-   Logout/revoke desteği olmalı

Şifre:

``` text
Plain password
```

olarak hiçbir yerde tutulmamalıdır.

Modern password hashing algoritması kullanılmalıdır.

------------------------------------------------------------------------

# 15. Authorization

Sadece:

``` csharp
if (user.IsAdmin)
```

yaklaşımı kullanılmamalıdır.

Gerektiğinde:

``` text
RBAC
+
Permission-based authorization
+
Policy-based authorization
```

kullanılmalıdır.

Örneğin:

``` text
User
Moderator
Admin
GameMaster
System
```

rolleri.

Ancak oyun içindeki davranışlar role göre hard-code edilmemelidir.

------------------------------------------------------------------------

# 16. User-Specific Behavior

Kullanıcının özellikle istediği önemli yapı budur:

> Aynı işlev, kullanıcı tipine veya modülüne göre farklı davranabilmeli.

Bunu:

``` csharp
if (user.Role == ...)
{
}
else if (...)
{
}
else if (...)
{
}
```

şeklinde her yere yaymak yanlış olur.

Bunun yerine:

## Strategy Pattern

``` text
IRewardStrategy
├── NormalUserRewardStrategy
├── PremiumUserRewardStrategy
└── ModeratorRewardStrategy
```

Örnek:

``` csharp
public interface IRewardStrategy
{
    Reward Calculate(RewardContext context);
}
```

Implementasyon:

``` csharp
public sealed class NormalUserRewardStrategy : IRewardStrategy
{
    public Reward Calculate(RewardContext context)
    {
        // Normal user reward
    }
}
```

``` csharp
public sealed class PremiumUserRewardStrategy : IRewardStrategy
{
    public Reward Calculate(RewardContext context)
    {
        // Premium user reward
    }
}
```

Böylece business logic tek bir dev `UserService` içine dolmaz.

------------------------------------------------------------------------

# 17. Aynı Class İsmi Konusu

Kullanıcının istediği senaryo:

> Farklı modüllerde aynı class adı olabilir ama davranış farklı
> olabilir.

Bu yapılabilir.

Örneğin:

``` text
Game/
└── Users/
    └── Strategies/
        ├── Normal/
        │   └── RewardCalculator.cs
        │
        └── Premium/
            └── RewardCalculator.cs
```

Namespace'ler farklıdır:

``` csharp
Fireman.Game.Users.Strategies.Normal.RewardCalculator
```

ve:

``` csharp
Fireman.Game.Users.Strategies.Premium.RewardCalculator
```

Ancak daha iyi yaklaşım genellikle class'ın rolünü açıkça belirtmektir:

``` text
NormalUserRewardStrategy
PremiumUserRewardStrategy
```

### Kural

Aynı isim sadece gerçekten aynı abstraction'ın farklı
implementation'ıysa kullanılmalıdır.

Sırf klasörleri temiz göstermek için aynı isimleri çoğaltmak tercih
edilmemelidir.

------------------------------------------------------------------------

# 18. Strategy Factory

Strategy seçimini merkezi hale getirmek için:

``` text
IRewardStrategyFactory
```

kullanılabilir.

``` csharp
public interface IRewardStrategyFactory
{
    IRewardStrategy Create(UserType userType);
}
```

Örnek:

``` text
UserType
   ↓
StrategyFactory
   ↓
NormalUserRewardStrategy
```

veya:

``` text
PremiumUserRewardStrategy
```

Bu yapı sayesinde Controller'ın kullanıcı tipini bilmesine gerek kalmaz.

------------------------------------------------------------------------

# 19. Daha Güçlü Yaklaşım: Policy

Bazı davranışlar Strategy değil Policy olmalıdır.

Örneğin:

``` text
CanBuyItemPolicy
CanJoinMatchPolicy
CanChangeUsernamePolicy
CanStartMissionPolicy
CanEquipItemPolicy
CanTradeItemPolicy
```

Interface:

``` csharp
public interface IGamePolicy<TContext>
{
    PolicyResult Evaluate(TContext context);
}
```

Bu yapı business rule'ları merkezileştirir.

------------------------------------------------------------------------

# 20. Specification Pattern

Karmaşık kurallar için Specification kullanılabilir.

Örneğin:

``` text
CanEnterMissionSpecification
```

şunları kontrol eder:

``` text
Player active?
Required level?
Required equipment?
Mission available?
Already in mission?
Cooldown finished?
```

Bunları Controller'a koymak yanlıştır.

------------------------------------------------------------------------

# 21. Character System

Her user'ın kendisine ait karakteri bulunmalıdır.

Temel model:

``` text
Character
----------------
Id
UserId
Name
Gender
BodyType
Skin
Hair
CreatedAt
UpdatedAt
```

Karakterin ekipmanları ayrı tutulmalıdır.

``` text
CharacterItem
----------------
Id
CharacterId
ItemId
Slot
EquippedAt
```

------------------------------------------------------------------------

# 22. Character Customization

Karakter:

``` text
Body
Face
Hair
HairColor
Skin
Top
Bottom
Shoes
Hat
Gloves
Accessory
BackItem
Emote
```

gibi slotlara ayrılabilir.

Örnek:

``` text
Character
   |
   +-- Head
   +-- Hair
   +-- Face
   +-- Body
   +-- Top
   +-- Bottom
   +-- Shoes
   +-- Hat
   +-- Gloves
   +-- Accessory
```

------------------------------------------------------------------------

# 23. Item Sistemi

Item bilgisi ile kullanıcı inventory kaydı ayrılmalıdır.

## ItemDefinition

Oyundaki item'ın tanımı:

``` text
Id
Name
Description
Type
Rarity
IsTradable
IsPurchasable
Price
AssetId
```

## InventoryItem

Kullanıcının sahip olduğu item:

``` text
Id
UserId
ItemDefinitionId
Quantity
AcquiredAt
```

Bu ayrım önemlidir.

Çünkü:

``` text
ItemDefinition = ürün
InventoryItem = oyuncunun sahip olduğu ürün
```

------------------------------------------------------------------------

# 24. Cosmetic Asset Güvenliği

Client'a:

``` text
"Bu item sende mi?"
```

sorusunun cevabını client vermemelidir.

Client:

``` text
EquipItem(itemId)
```

der.

Server:

``` text
User owns item?
       ↓
Yes → Equip
No  → Reject
```

Bu kontrol server'da yapılmalıdır.

------------------------------------------------------------------------

# 25. Offline Mode

Offline oyun gerçek bir account-authoritative server gibi çalışamaz.

Bu nedenle iki state ayrılmalıdır:

``` text
Local Game State
Server Game State
```

Offline:

``` text
Local Save
 ↓
Encrypted / Integrity Protected
 ↓
Gameplay
```

Online:

``` text
Server State
 ↓
Gameplay
 ↓
Server Validation
```

------------------------------------------------------------------------

# 26. Offline → Online Sync

Oyuncu offline oynadıktan sonra:

``` text
Offline Session
      ↓
Pending Operations
      ↓
Sync Queue
      ↓
Server
      ↓
Validation
      ↓
Accepted / Rejected
```

kullanılmalıdır.

Client:

``` text
"I earned 500 coins"
```

dememelidir.

Bunun yerine:

``` text
"MissionCompleted"
```

gibi doğrulanabilir operasyon göndermelidir.

Server:

``` text
Mission gerçekten tamamlanabilir miydi?
Reward ne olmalı?
Daha önce tamamlandı mı?
```

kontrol eder.

------------------------------------------------------------------------

# 27. Offline Hile Riski

Offline currency, XP ve inventory değerleri client tarafından
değiştirilebilir.

Bu nedenle yüksek değerli online economy tamamen client'a
güvenmemelidir.

Özellikle:

``` text
Coins
Premium Currency
Rare Items
Inventory
Leaderboard Score
Competitive XP
Match Result
```

server-authoritative olmalıdır.

Offline progression gerekiyorsa online sync sırasında server doğrulaması
uygulanmalıdır.

------------------------------------------------------------------------

# 28. Server Authoritative Model

Online multiplayer için temel kural:

> Client karar vermez, input gönderir.

Yanlış:

``` text
Client:
Player.Position = 500
```

Doğru:

``` text
Client:
MoveInput(direction)
       ↓
Server
       ↓
Validation
       ↓
New State
```

Aynı şekilde:

``` text
Client → CompleteMission
Server → Validate
Server → Reward
```

------------------------------------------------------------------------

# 29. Multiplayer

Gerçek zamanlı sistem için:

``` text
HTTPS
```

API işlemleri için;

``` text
WebSocket
```

veya uygun real-time transport kullanılabilir.

Örnek:

``` text
REST
- Login
- Inventory
- Profile
- Missions

Real-Time
- Player movement
- Match state
- Fire state
- Team state
- Multiplayer events
```

------------------------------------------------------------------------

# 30. Event-Driven Game System

Oyun event'leri ayrı tanımlanmalıdır.

``` text
Domain/
└── Events/
    ├── UserRegisteredEvent.cs
    ├── CharacterCreatedEvent.cs
    ├── MissionStartedEvent.cs
    ├── MissionCompletedEvent.cs
    ├── ItemEquippedEvent.cs
    ├── ItemPurchasedEvent.cs
    ├── MatchCreatedEvent.cs
    ├── MatchCompletedEvent.cs
    └── RewardGrantedEvent.cs
```

Event ile Command birbirine karıştırılmamalıdır.

``` text
Command:
"Mission'ı tamamla."

Event:
"Mission tamamlandı."
```

------------------------------------------------------------------------

# 31. Outbox Pattern

Özellikle kritik event'lerde Outbox Pattern kullanılmalıdır.

Problem:

``` text
Database update
      ↓
Event publish
```

Database başarılı ama event publish başarısız olabilir.

Outbox:

``` text
Transaction
 ├── Game State
 └── Outbox Event
        ↓
Commit
        ↓
Background Publisher
        ↓
Message Bus
```

Bu yapı data consistency açısından önemlidir.

------------------------------------------------------------------------

# 32. Idempotency

Aynı request iki kere gelirse iki kere ödül verilmemelidir.

Örnek:

``` text
MissionCompleted
OperationId = ABC123
```

Server:

``` text
ABC123 daha önce işlendi mi?
```

Evet:

``` text
Aynı sonucu döndür
```

Hayır:

``` text
İşle
```

Bu özellikle mobil bağlantı problemlerinde kritiktir.

------------------------------------------------------------------------

# 33. Database

Önerilen başlangıç:

``` text
PostgreSQL
```

Temel tablolar:

``` text
Users
UserSessions
Characters
CharacterItems
ItemDefinitions
Inventories
Missions
MissionProgress
Rewards
Matches
MatchPlayers
GameEvents
OutboxMessages
AuditLogs
```

------------------------------------------------------------------------

# 34. Redis

Redis şu amaçlarla kullanılabilir:

``` text
Session
Cache
Rate Limiting
Distributed Lock
Presence
Matchmaking state
Temporary game state
```

Redis database'in yerine kullanılmamalıdır.

------------------------------------------------------------------------

# 35. Security Katmanları

Minimum güvenlik:

``` text
TLS
JWT / Session security
Refresh token rotation
Password hashing
Rate limiting
Input validation
Output encoding
SQL injection protection
CORS
CSRF strategy
Security headers
Audit logs
Account lockout
Brute-force protection
Device/session management
```

------------------------------------------------------------------------

# 36. Rate Limiting

Özellikle:

``` text
Login
Register
Username change
Password reset
Match creation
Mission actions
Reward claims
Chat
Friend requests
```

rate-limit edilmelidir.

Örneğin:

``` text
5 login attempts / minute
```

gibi kurallar ürün gereksinimine göre belirlenir.

Limitler kod içine magic number olarak gömülmemelidir.

------------------------------------------------------------------------

# 37. Audit Log

Önemli işlemler loglanmalıdır:

``` text
Login
Logout
UsernameChanged
PasswordChanged
ItemPurchased
ItemEquipped
CurrencyChanged
RewardGranted
MissionCompleted
AccountBanned
AdminAction
```

Audit log:

``` text
Who
What
When
Where
Before
After
CorrelationId
```

bilgilerini gerektiği ölçüde taşımalıdır.

------------------------------------------------------------------------

# 38. Admin ve Moderation

Oyuncu sistemi ile admin sistemi ayrılmalıdır.

``` text
Player API
Admin API
```

ayrı authorization policy'lerine sahip olmalıdır.

Admin işlemleri audit edilmelidir.

Örneğin:

``` text
Admin → AddCurrency
```

işlemi:

``` text
AuditLog
```

oluşturmalıdır.

------------------------------------------------------------------------

# 39. Chat ve Sosyal Sistem

Online oyunda:

``` text
Friends
FriendRequests
BlockList
Chat
Reports
Mute
Moderation
```

ayrı modüller olmalıdır.

Kullanıcı-generated content olduğu için:

``` text
Spam protection
Rate limit
Profanity filter
Report system
Block system
Moderation logs
```

uygulanmalıdır.

------------------------------------------------------------------------

# 40. User Module

``` text
Modules/
└── Users/
    ├── Domain/
    ├── Application/
    ├── Infrastructure/
    └── Contracts/
```

Her modül kendi boundary'sine sahip olmalıdır.

Örnek:

``` text
Users
Characters
Inventory
Missions
Matches
Social
Rewards
Notifications
```

birbirinin internal implementation'ına doğrudan erişmemelidir.

------------------------------------------------------------------------

# 41. Module Communication

Yanlış:

``` text
InventoryService
   ↓
UserService.InternalDatabaseObject
```

Doğru:

``` text
Inventory
   ↓
IUserContext
```

veya event:

``` text
UserRegisteredEvent
```

ile iletişim kurulmasıdır.

------------------------------------------------------------------------

# 42. Dependency Injection

Dependency Injection kullanılmalıdır.

Örnek:

``` csharp
public class CompleteMissionHandler
{
    private readonly IMissionRepository _missionRepository;
    private readonly IRewardService _rewardService;

    public CompleteMissionHandler(
        IMissionRepository missionRepository,
        IRewardService rewardService)
    {
        _missionRepository = missionRepository;
        _rewardService = rewardService;
    }
}
```

Concrete dependency doğrudan oluşturulmamalıdır.

Yanlış:

``` csharp
var repository = new PostgreSqlMissionRepository();
```

------------------------------------------------------------------------

# 43. Repository Pattern

Repository domain/application sınırında abstraction sağlar.

``` csharp
public interface IMissionRepository
{
    Task<Mission?> GetByIdAsync(Guid id);
    Task SaveAsync(Mission mission);
}
```

Infrastructure:

``` csharp
public sealed class PostgreSqlMissionRepository
    : IMissionRepository
{
}
```

Repository her database query'sini gizlemek için otomatik olarak
kullanılmamalıdır.

Query-heavy read işlemlerinde ayrı read/query abstraction
kullanılabilir.

------------------------------------------------------------------------

# 44. CQRS

Bu projede CQRS kullanılabilir.

Özellikle:

``` text
Commands
- EquipItem
- BuyItem
- CompleteMission
- JoinMatch

Queries
- GetCharacter
- GetInventory
- GetLeaderboard
- GetProfile
```

ayrılabilir.

Ancak her şeyi gereksiz yere CQRS framework'üne dönüştürmekten
kaçınılmalıdır.

------------------------------------------------------------------------

# 45. DTO Kuralları

Entity doğrudan API response olarak gönderilmemelidir.

Yanlış:

``` csharp
return Ok(userEntity);
```

Doğru:

``` text
UserEntity
    ↓
UserProfileResponse
```

DTO'lar ayrı klasörde tutulmalıdır:

``` text
Contracts/
├── Auth/
├── Users/
├── Characters/
├── Inventory/
├── Missions/
└── Matches/
```

------------------------------------------------------------------------

# 46. Error Handling

Standart hata contract'ı kullanılmalıdır.

Örnek:

``` json
{
  "code": "ITEM_NOT_OWNED",
  "message": "The item is not owned by the player.",
  "traceId": "..."
}
```

Client'ın:

``` text
"Bir hata oluştu"
```

dışında gerektiğinde güvenli şekilde aksiyon alabilmesi için
machine-readable error code bulunmalıdır.

Sensitive internal exception detayları client'a gönderilmemelidir.

------------------------------------------------------------------------

# 47. Result Pattern

Beklenen business failure durumlarında exception kullanımı
abartılmamalıdır.

Örneğin:

``` text
ItemNotOwned
InsufficientCurrency
MissionAlreadyCompleted
MatchFull
UsernameTaken
```

gibi durumlar Result/Domain Error ile temsil edilebilir.

Exception daha çok beklenmeyen teknik hatalar için kullanılmalıdır.

------------------------------------------------------------------------

# 48. Validation

Validation katmanları:

``` text
Transport Validation
        ↓
Application Validation
        ↓
Domain Validation
```

Örneğin:

``` text
Username boş mu?
```

application/contract validation olabilir.

Ama:

``` text
Bu item bu karakter tarafından kuşanabilir mi?
```

domain rule olmalıdır.

------------------------------------------------------------------------

# 49. State Machine

Mission ve Match gibi sistemlerde if-else zinciri yerine state machine
yaklaşımı tercih edilmelidir.

Örneğin Mission:

``` text
Locked
 ↓
Available
 ↓
Started
 ↓
Completed
```

ve:

``` text
Started
 ↓
Failed
```

Geçersiz transition:

``` text
Completed → Started
```

engellenmelidir.

------------------------------------------------------------------------

# 50. Game Session State

Bir multiplayer match:

``` text
Waiting
 ↓
Preparing
 ↓
Running
 ↓
Completed
```

durumlarına sahip olabilir.

Her transition kontrollü olmalıdır.

------------------------------------------------------------------------

# 51. Concurrency

Aynı anda:

``` text
Player A buys item
Player A equips item
Player A spends currency
```

gibi işlemler gelebilir.

Currency için:

``` text
Optimistic Concurrency
```

veya gerekli yerlerde transactional locking kullanılmalıdır.

Aynı reward'ın iki kere verilmesini:

``` text
Unique constraint
+
Idempotency
+
Transaction
```

kombinasyonu ile korumak gerekir.

------------------------------------------------------------------------

# 52. Inventory Transaction

Örnek:

``` text
BuyItem
```

işlemi:

``` text
BEGIN TRANSACTION

Check balance
Check item availability
Deduct currency
Create inventory item
Create audit
Create outbox event

COMMIT
```

şeklinde atomik tasarlanmalıdır.

------------------------------------------------------------------------

# 53. Client Security

Mobil client güvenilir bir kaynak değildir.

Client'ta:

``` text
Secret key
Admin credential
Database password
JWT signing secret
Payment private key
```

bulundurulmamalıdır.

APK/IPA içindeki kodun reverse-engineer edilebileceği varsayılmalıdır.

------------------------------------------------------------------------

# 54. Anti-Cheat

Özellikle online modda:

``` text
Server authoritative
Movement validation
Action validation
Rate validation
Timestamp validation
Impossible state detection
Duplicate operation detection
```

uygulanmalıdır.

Örneğin:

``` text
Player moved 10 meters
```

normal olabilir.

Ama:

``` text
Player moved 10 km in 1 second
```

server tarafından reddedilebilir veya flag'lenebilir.

------------------------------------------------------------------------

# 55. Anti-Cheat Event Log

Şüpheli hareketler:

``` text
ImpossibleMovement
ImpossibleReward
ImpossibleCurrencyChange
InvalidItemEquip
DuplicateMissionCompletion
InvalidMatchResult
```

event olarak loglanabilir.

Bunlar otomatik ban anlamına gelmemelidir.

Önce:

``` text
Detection
↓
Score
↓
Review / Action
```

sistemi tercih edilmelidir.

------------------------------------------------------------------------

# 56. Save System

Offline save:

``` text
Local Save
```

Online save:

``` text
Server Save
```

olarak ayrılmalıdır.

Save formatının versiyonu bulunmalıdır:

``` json
{
  "saveVersion": 3
}
```

Böylece gelecekte migration yapılabilir.

------------------------------------------------------------------------

# 57. Local Storage

Client tarafında:

``` text
Settings
Graphics
Audio
Control preferences
Last selected cosmetic
Offline temporary state
```

saklanabilir.

Ancak güvenlik açısından kritik bilgiler düz text tutulmamalıdır.

Platform secure storage mekanizması kullanılmalıdır.

------------------------------------------------------------------------

# 58. Asset / Character ID Sistemi

Client'a:

``` text
assetId
```

gönderilebilir.

Örneğin:

``` text
firefighter_helmet_001
firefighter_jacket_004
boots_002
```

Ancak client'ın gönderdiği assetId'nin oyuncuya ait olup olmadığı
server'da doğrulanmalıdır.

------------------------------------------------------------------------

# 59. Feature Flag

Yeni özellikleri kontrollü açmak için:

``` text
FeatureFlags
```

kullanılabilir.

Örnek:

``` text
EnableMultiplayer
EnableTrading
EnableNewCharacterSystem
EnableNewMissionType
EnableSeasonSystem
```

Canary rollout yapılabilir.

------------------------------------------------------------------------

# 60. Logging

Structured logging kullanılmalıdır.

Örnek:

``` json
{
  "event": "MissionCompleted",
  "userId": "...",
  "missionId": "...",
  "correlationId": "..."
}
```

String concatenation ile log üretmekten kaçınılmalıdır.

------------------------------------------------------------------------

# 61. Observability

Minimum:

``` text
Logs
Metrics
Traces
Health Checks
```

Ölçülmesi gerekenler:

``` text
API latency
p95
p99
Error rate
Login failure rate
Match creation rate
Match completion rate
Reward failures
Database latency
Redis latency
Queue depth
Active players
Concurrent matches
```

------------------------------------------------------------------------

# 62. Correlation ID

Her request:

``` text
CorrelationId
```

taşımalıdır.

Örneğin:

``` text
Mobile
 ↓
API
 ↓
Mission Service
 ↓
Database
 ↓
Event Bus
```

aynı correlation/trace context ile izlenebilmelidir.

------------------------------------------------------------------------

# 63. Testing Strategy

## Unit Test

Domain rule:

``` text
CanEquipItem
CanCompleteMission
CanBuyItem
CanChangeUsername
```

test edilir.

## Integration Test

``` text
API
+
PostgreSQL
+
Redis
```

ile gerçek entegrasyon test edilir.

## End-to-End

``` text
Register
 ↓
Create Character
 ↓
Play Mission
 ↓
Reward
 ↓
Inventory
```

uçtan uca test edilir.

## Load Test

Özellikle:

``` text
Login
Matchmaking
Mission completion
Leaderboard
Inventory
```

yük altında test edilmelidir.

------------------------------------------------------------------------

# 64. Architecture Tests

Projenin mimarisinin bozulmasını otomatik testlerle engelleyin.

Örneğin:

``` text
Domain
```

şunlara bağımlı olamaz:

``` text
Infrastructure
API
Database
Redis
```

Architecture test:

``` text
Domain → Infrastructure dependency = FAIL
```

olmalıdır.

------------------------------------------------------------------------

# 65. Dependency Direction

Ana kural:

``` text
Api
 ↓
Application
 ↓
Domain
```

Infrastructure ise Application/Domain abstraction'larını implement eder.

Örnek:

``` text
Application → IMissionRepository
Infrastructure → PostgreSqlMissionRepository
```

Domain PostgreSQL'i bilmez.

------------------------------------------------------------------------

# 66. Naming Convention

Dosya ve class isimleri açık olmalıdır.

``` text
CreateMissionCommand
CreateMissionCommandHandler
CreateMissionValidator
CreateMissionResponse
```

gibi.

Generic isimlerden kaçınılmalıdır:

``` text
Manager
Helper
Utility
CommonService
DataService
GeneralService
```

özellikle business logic taşıyan sınıflarda kullanılmamalıdır.

------------------------------------------------------------------------

# 67. God Class Yasağı

Şu tarz class oluşturulmamalıdır:

``` text
GameService
```

ve içerisinde:

``` text
Login
Register
BuyItem
EquipItem
StartMission
CompleteMission
CreateMatch
SendMessage
GiveReward
```

gibi onlarca method bulunmamalıdır.

Bunun yerine:

``` text
AuthService
InventoryService
CharacterService
MissionService
MatchService
RewardService
SocialService
```

ayrılmalıdır.

Ancak bunlar da sonsuz büyürse use-case bazlı handler'lara bölünmelidir.

------------------------------------------------------------------------

# 68. User Context

Her request için:

``` text
IUserContext
```

gibi abstraction bulunabilir.

Örneğin:

``` csharp
public interface IUserContext
{
    Guid UserId { get; }
    UserRole Role { get; }
    bool IsAuthenticated { get; }
}
```

Business logic:

``` text
HttpContext
```

bilmek zorunda kalmaz.

------------------------------------------------------------------------

# 69. User Type Strategy

Örnek:

``` text
UserType
├── Standard
├── Premium
├── Moderator
└── Admin
```

Fakat her işlemde:

``` csharp
switch(user.Type)
```

yapılmamalıdır.

Bunun yerine:

``` text
IRewardStrategy
IPricingStrategy
IMatchPolicy
ICharacterCustomizationPolicy
```

gibi abstraction'lar oluşturulabilir.

------------------------------------------------------------------------

# 70. Pricing Strategy Örneği

``` csharp
public interface IPricingStrategy
{
    Price Calculate(ItemDefinition item, UserContext user);
}
```

Implementasyon:

``` text
StandardPricingStrategy
PremiumPricingStrategy
EventPricingStrategy
```

Factory:

``` text
PricingStrategyFactory
```

ile seçilebilir.

------------------------------------------------------------------------

# 71. User Module'a Göre Davranış

Kullanıcıya göre değil, mümkün olduğunca **domain capability**'ye göre
tasarım yapılmalıdır.

Örneğin:

``` text
Premium user
```

yerine:

``` text
CanAccessPremiumMission
CanUsePremiumCosmetics
HasDiscount
```

gibi capability/policy kontrolleri daha esnek olabilir.

Bu ileride subscription sistemini değiştirmeyi kolaylaştırır.

------------------------------------------------------------------------

# 72. Event Handler Isolation

Bir event'in handler'ları birbirine bağımlı olmamalıdır.

``` text
MissionCompleted
      |
      +--> RewardHandler
      |
      +--> AchievementHandler
      |
      +--> AnalyticsHandler
      |
      +--> NotificationHandler
```

RewardHandler'ın AnalyticsHandler'ı çağırması doğru değildir.

------------------------------------------------------------------------

# 73. Background Jobs

Aşağıdaki işlemler background worker'a taşınabilir:

``` text
Event processing
Email
Push notification
Analytics
Cleanup
Expired sessions
Leaderboard calculation
Anti-cheat analysis
Outbox publishing
```

------------------------------------------------------------------------

# 74. Notification System

Notification provider abstraction:

``` text
INotificationService
```

implementasyonlar:

``` text
PushNotificationService
EmailNotificationService
InAppNotificationService
```

olabilir.

Event:

``` text
MissionCompleted
```

sonrasında notification gönderilebilir.

------------------------------------------------------------------------

# 75. Analytics

Analytics sistemi gameplay logic'e gömülmemelidir.

Örneğin:

``` text
MissionCompleted
```

event'i analytics consumer tarafından işlenir.

Ölçülebilecek metrikler:

``` text
DAU
MAU
Session Length
Retention
Mission Completion Rate
Match Completion Rate
Character Customization Usage
Item Popularity
Currency Economy
Churn
```

------------------------------------------------------------------------

# 76. Economy Security

Oyun ekonomisinde en kritik kural:

> Currency değişikliği tek bir güvenilir business path üzerinden
> yapılmalıdır.

Yanlış:

``` csharp
user.Coins += 500;
```

her yerde yapılması.

Doğru:

``` text
ICurrencyService
```

veya domain aggregate üzerinden kontrollü mutation.

Örnek:

``` text
Earn
Spend
Refund
Grant
Revoke
Transfer
```

işlemleri ayrı kurallara sahip olmalıdır.

------------------------------------------------------------------------

# 77. Currency Ledger

Daha ciddi ekonomi için:

``` text
CurrencyAccount
CurrencyTransaction
```

yapısı kurulabilir.

Örneğin:

``` text
+500 MissionReward
-200 ItemPurchase
+100 DailyReward
```

Böylece:

``` text
Current Balance
```

ile birlikte transaction geçmişi tutulabilir.

Bu audit ve anti-cheat için değerlidir.

------------------------------------------------------------------------

# 78. Leaderboard

Leaderboard için:

``` text
PostgreSQL
+
Redis sorted sets
```

kombinasyonu değerlendirilebilir.

Ancak authoritative score server'da tutulmalıdır.

Client:

``` text
score = 999999999
```

göndererek leaderboard'a yazamamalıdır.

------------------------------------------------------------------------

# 79. API Versioning

İlk günden:

``` text
/api/v1/
```

gibi versioning standardı uygulanabilir.

Örneğin:

``` text
/api/v1/auth/login
/api/v1/characters/me
/api/v1/inventory
/api/v1/missions
```

Breaking change gerektiğinde:

``` text
/api/v2/
```

kullanılabilir.

------------------------------------------------------------------------

# 80. API Endpoint Grupları

Minimum API:

``` text
AUTH
POST   /api/v1/auth/register
POST   /api/v1/auth/login
POST   /api/v1/auth/refresh
POST   /api/v1/auth/logout

USERS
GET    /api/v1/users/me
PATCH  /api/v1/users/me
PATCH  /api/v1/users/me/username

CHARACTER
GET    /api/v1/characters/me
PATCH  /api/v1/characters/me
POST   /api/v1/characters/me/equip

INVENTORY
GET    /api/v1/inventory
POST   /api/v1/inventory/purchase
POST   /api/v1/inventory/equip

MISSIONS
GET    /api/v1/missions
POST   /api/v1/missions/{id}/start
POST   /api/v1/missions/{id}/complete

MATCH
POST   /api/v1/matches
POST   /api/v1/matches/{id}/join
POST   /api/v1/matches/{id}/leave

SOCIAL
GET    /api/v1/friends
POST   /api/v1/friends/requests
POST   /api/v1/friends/{id}/accept
POST   /api/v1/users/{id}/block

LEADERBOARD
GET    /api/v1/leaderboards
```

Endpoint list ürün geliştikçe genişletilmelidir.

------------------------------------------------------------------------

# 81. API'de Client'a Güvenilmeyecek Veriler

Aşağıdaki değerler client'tan geldiği haliyle kabul edilmemelidir:

``` text
Reward amount
Currency amount
XP amount
Item ownership
Item price
Mission result
Match result
Player score
Admin status
Premium status
Cooldown completion
```

Bunların tamamı server tarafından hesaplanmalı veya doğrulanmalıdır.

------------------------------------------------------------------------

# 82. Offline / Online Conflict Resolution

Örneğin:

``` text
Offline:
Mission A completed
+100 coin
```

Online sync sırasında:

``` text
Mission A already completed?
```

Evetse:

``` text
Duplicate → reject reward
```

Hayırsa:

``` text
Validate
→ Apply
→ Ledger
→ Event
```

Bu sistem olmadan offline mode kolayca exploit edilebilir.

------------------------------------------------------------------------

# 83. Database Constraints

Business rule'ların bir kısmı database seviyesinde de korunmalıdır.

Örneğin:

``` text
UNIQUE username
UNIQUE normalized_username
UNIQUE inventory(user_id, item_id)
UNIQUE operation_id
```

Database constraint son savunma hattıdır.

------------------------------------------------------------------------

# 84. Transaction Boundary

Transaction mümkün olduğunca application use-case sınırında
düşünülmelidir.

Örneğin:

``` text
PurchaseItemUseCase
```

tek bir business transaction olabilir.

Her repository methoduna ayrı transaction açmak yanlış sonuçlar
doğurabilir.

------------------------------------------------------------------------

# 85. Cache Strategy

Cache:

``` text
Character cosmetics
Item definitions
Mission definitions
Leaderboard
Public profile
```

gibi sık okunan verilerde kullanılabilir.

Cache key standardı:

``` text
fireman:user:{userId}
fireman:character:{characterId}
fireman:item:{itemId}
fireman:leaderboard:{seasonId}
```

gibi merkezi şekilde yönetilmelidir.

------------------------------------------------------------------------

# 86. Cache Invalidation

Cache'e veri koymak kolaydır.

Asıl problem:

> Ne zaman invalidate edeceğiz?

Örneğin:

``` text
EquipItem
 ↓
DB update
 ↓
Character cache invalidation
```

Event-driven invalidation kullanılabilir.

------------------------------------------------------------------------

# 87. Season System

İleride sezon sistemi gelirse:

``` text
Season
SeasonReward
SeasonMission
SeasonLeaderboard
```

ayrı module olarak tasarlanabilir.

Global event:

``` text
SeasonStarted
SeasonEnded
```

kullanılabilir.

------------------------------------------------------------------------

# 88. Feature Module Standardı

Her yeni modül için standart:

``` text
ModuleName/
├── Domain/
├── Application/
├── Infrastructure/
├── Contracts/
└── ModuleRegistration.cs
```

Örnek:

``` text
Inventory/
├── Domain/
│   ├── Inventory.cs
│   └── InventoryItem.cs
├── Application/
│   ├── PurchaseItem/
│   └── EquipItem/
├── Infrastructure/
│   └── InventoryRepository.cs
└── Contracts/
    └── InventoryResponse.cs
```

Bu standardın bozulmasına izin verilmemelidir.

------------------------------------------------------------------------

# 89. Kod Organizasyonu İçin Ana Kurallar

1.  Enum'lar ayrı dosya.
2.  DTO'lar entity'lerden ayrı.
3.  Domain entity'leri API response olarak dönülmez.
4.  Controller business logic içermez.
5.  Infrastructure domain'e sızmaz.
6.  Domain infrastructure'ı bilmez.
7.  Kullanıcı tiplerine göre if/switch kodu yayılmaz.
8.  Strategy/Policy/Specification kullanılır.
9.  Event handler'lar birbirine bağımlı olmaz.
10. Critical state server authoritative olur.
11. Offline state sync sırasında validate edilir.
12. Idempotency kritik command'lerde zorunludur.
13. Currency ledger/audit kritik ekonomi için tutulur.
14. Secrets client'a koyulmaz.
15. Magic string ve magic number azaltılır.
16. God class oluşturulmaz.
17. God method oluşturulmaz.
18. Her modül kendi boundary'sini korur.
19. Test edilebilirlik DI ile korunur.
20. Mimari dependency testleri otomatik kontrol eder.

------------------------------------------------------------------------

# 90. Önerilen Son Proje Yapısı

``` text
Fireman
│
├── client/
│   └── Fireman.Mobile/
│       ├── Views/
│       ├── ViewModels/
│       ├── Models/
│       ├── Services/
│       ├── Repositories/
│       ├── LocalStorage/
│       ├── Networking/
│       └── Assets/
│
├── server/
│   ├── Fireman.Api/
│   ├── Fireman.Application/
│   ├── Fireman.Domain/
│   ├── Fireman.Infrastructure/
│   ├── Fireman.Contracts/
│   └── Fireman.Shared/
│
├── tests/
│   ├── Fireman.UnitTests/
│   ├── Fireman.IntegrationTests/
│   ├── Fireman.E2ETests/
│   └── Fireman.ArchitectureTests/
│
└── docs/
    ├── Architecture/
    ├── Security/
    ├── API/
    ├── GameDesign/
    └── Operations/
```

------------------------------------------------------------------------

# 91. Teknoloji Önerisi

Backend:

``` text
.NET / ASP.NET Core
C#
PostgreSQL
Redis
Message Broker
OpenTelemetry
Docker
```

Mobile/game client:

``` text
Unity
C#
MVVM-inspired presentation architecture
Local persistence
Secure platform storage
```

Gerçek zamanlı multiplayer için ihtiyaçlara göre:

``` text
WebSocket
veya
Dedicated Game Server / uygun real-time networking solution
```

kullanılabilir.

Message broker seçiminde:

``` text
RabbitMQ
```

başlangıç için yeterli olabilir.

Çok yüksek event throughput ve replay ihtiyacı oluşursa Kafka
değerlendirilebilir.

------------------------------------------------------------------------

# 92. Neden Microservice Değil?

İlk sürümde:

``` text
Identity Service
Game Service
Inventory Service
Reward Service
Match Service
Notification Service
Analytics Service
```

diye 7 servis açmak cazip görünebilir.

Ancak bunun maliyeti:

``` text
Network calls
Service discovery
Deployment
Monitoring
Distributed tracing
Distributed transactions
Message consistency
Local development complexity
```

getirir.

Oyunun ilk aşamasında bunlar gereksizdir.

Bunun yerine:

``` text
Modular Monolith
```

kurulur.

Modüller boundary'lerle ayrılır.

İleride gerçekten ihtiyaç varsa:

``` text
Inventory
```

örneğin ayrı servise çıkarılabilir.

------------------------------------------------------------------------

# 93. Ne Zaman Microservice'e Geçilir?

Şu sinyaller oluştuğunda:

``` text
Independent scaling requirement
Independent deployment requirement
Team ownership separation
Different technology requirements
Strong module boundary
High traffic isolation
Failure isolation requirement
```

Microservice düşünülebilir.

Sırf "modern" olduğu için microservice yapılmamalıdır.

------------------------------------------------------------------------

# 94. Mimari Özet

Final karar:

``` text
                 FIREMAN MOBILE
                       |
              ┌────────┴────────┐
              |                 |
           CLIENT             SERVER
              |                 |
             MVVM          Layered Architecture
              |                 |
       Local Repository    Application
              |                 |
       Offline State       Domain
              |                 |
        Sync Engine        Infrastructure
                                |
                    ┌───────────┼───────────┐
                    |           |           |
                PostgreSQL    Redis      Message Bus
                                            |
                                      Event-Driven
```

Ve davranış tarafında:

``` text
User / Context
      ↓
Policy / Strategy / Specification
      ↓
Use Case
      ↓
Domain
      ↓
Transaction
      ↓
Event
      ↓
Handlers
```

Bu yapı oyunun büyümesini engellemeden başlangıçta yönetilebilir kalır.

------------------------------------------------------------------------

# 95. En Kritik Tasarım İlkeleri

Bu proje için özellikle şu prensipler zorunlu kabul edilmelidir:

### 1. Client'a güvenme

``` text
Client = Input Source
Server = Authority
```

### 2. Business logic'i Controller'a koyma

``` text
Controller → Use Case → Domain
```

### 3. User type switch'lerini her yere yayma

``` text
Strategy
Policy
Specification
Capability
```

kullan.

### 4. Kritik işlemleri idempotent yap

``` text
OperationId
Idempotency-Key
Unique Constraint
```

### 5. Offline mode'u güvenilir kaynak kabul etme

``` text
Offline → Sync → Validate → Apply
```

### 6. Event ile yan etkileri ayır

``` text
Core operation
     ↓
Domain Event
     ↓
Side effects
```

### 7. Modül sınırlarını koru

``` text
Users ≠ Inventory ≠ Missions ≠ Match
```

### 8. Enum, DTO, Configuration ve Constant'ları düzenli ayır

Kod organizasyonu projenin büyümesiyle kritik hale gelir.

### 9. Microservice'e erken geçme

Önce:

``` text
Modular Monolith
```

sonra gerekirse:

``` text
Microservices
```

### 10. Ölçmeden optimize etme

``` text
Logs
Metrics
Traces
Profiling
```

üzerinden karar ver.

------------------------------------------------------------------------

# 96. Sonuç

Fireman Mobile için önerilen mimari:

> **Modular Monolith + Layered/N-Tier Architecture + Event-Driven
> Architecture + MVVM Client Architecture +
> Strategy/Policy/Specification tabanlı davranış sistemi +
> Server-Authoritative Multiplayer + Offline Sync**

şeklindedir.

Bu kombinasyon:

-   İlk sürümün gereksiz yere karmaşıklaşmasını engeller.
-   Multiplayer ve online economy için güvenli temel oluşturur.
-   Offline desteğini mümkün kılar.
-   Kullanıcıya özel karakter sistemini modüler tutar.
-   Aynı işlevin farklı kullanıcı/modül tiplerinde farklı davranmasına
    izin verir.
-   Enum ve contract organizasyonunu standartlaştırır.
-   Event-driven işlemlerle coupling'i azaltır.
-   Gelecekte microservice'e geçiş için boundary'ler oluşturur.
-   Test, observability, security ve anti-cheat ihtiyaçlarını mimarinin
    parçası haline getirir.

En önemli prensip:

> **Önce doğru domain boundary'lerini ve business rule'ları oluştur;
> teknolojiyi bunların etrafına yerleştir.**

Bu proje için hedef yalnızca çalışan bir mobil oyun değil,
**online/offline, güvenli, test edilebilir, ölçeklenebilir ve ileride
genişletilebilir bir oyun platformu** oluşturmaktır.

# 🚒 FIREMAN • Proje Geliştirme ve Mimari Raporu

Bu rapor, `Fireman_Mobile_Teknik_Mimari.md` şartnamesine ve devamında geliştirilen **"Playing with Fire 2" (Bomberman)** oyun mekaniklerine uygun olarak hayata geçirilen tüm sistemleri, mimari katmanları ve bileşenleri detaylandırmaktadır.

---

## 📌 Proje Genel Özeti
* **Mimari:** Modüler Monolit (Modular Monolith) + Katmanlı Mimari (N-Tier) + Olay Odaklı (Event-Driven) + Sunucu Otoriter (Server-Authoritative Anti-Cheat) + MVVM.
* **Backend:** .NET 10 (C#), ASP.NET Core, SignalR, Entity Framework Core, PostgreSQL Npgsql Provider, In-Memory DB & Cache.
* **Mobil İstemci:** Flutter 3.41+ (Dart 3.11+), Provider (MVVM), CustomPaint 2D Arcade Motoru, SharedPreferences.
* **Web Arayüzü & Simülatör:** HTML5 Canvas, Vanilla JS, SignalR WebSocket İstemcisi, CSS Glassmorphism Karanlık Tema.
* **Kaynak Kod Deposu:** [GitHub - alperenaykutlu/fireman](https://github.com/alperenaykutlu/fireman.git) (Branch: `master`)

---

## 🏗️ 1. Backend Katmanları (.NET 10 / C#)

### 1.1 Fireman.Shared
* **Enum Ayrımı Kuralı:** Mimari dokümanda belirtilen "her enum kendi dosyasında olmalı" kuralına göre 16 ayrı enum dosyası oluşturuldu:
  - `UserRole`, `UserStatus`, `CharacterSlot`, `ItemRarity`, `ItemType`, `MissionStatus`, `MissionType`, `MatchStatus`, `MatchType`, `CurrencyType`, `NotificationType`, `AntiCheatSeverity`, `FriendshipStatus`, `ReportReason`, `MissionTrigger`, `MatchTrigger`.
* **Ortak Yapılar:** `Result<T>`, `Error`, `PagedResult<T>`, `DomainException`, `GameLimits`, `CacheKeys`.

### 1.2 Fireman.Contracts (DTO Katmanı)
* REST API ve SignalR sözleşmeleri:
  - `AuthContracts`, `UserContracts`, `CharacterContracts`, `InventoryContracts`, `MissionContracts`, `MatchContracts`, `MatchRealtimeContracts` (3D pozisyon, rotasyon, su/patlama aksiyonu), `LeaderboardContracts`, `OfflineSyncContracts`, `AdminContracts`, `FeatureFlagContracts`, `SocialContracts`, `WalletContracts`, `SeasonContracts`, `NotificationContracts`.

### 1.3 Fireman.Domain (İş Çekirdeği)
* **Aggregate Root & Entity:**
  - `User` (PBKDF2 SHA-256 şifreleme, Refresh Token yönetimi, Askıya alma / Banlama).
  - `Character` (Karakter ekipmanları, seviye ve XP hesaplama).
  - `InventoryItem` & `ItemDefinition` (Envanter sahipliği, nadirlik, istifleme).
  - `Mission` & `UserMission` (Görev ilerleme durumu, hedef skor).
  - `Match` & `MatchPlayer` (Çok oyunculu lobi, oda yönetimi, skor kaydı).
  - `Wallet` & `CurrencyLedgerEntry` (Çift girişli para defteri, altın ve elmas takibi).
  - `AuditLog` (Admin denetim izleri, CorrelationId desteği).
  - `AntiCheatLog` (Hile tespit kayıtları, istemci ve sunucu zaman damgaları, JSON metadata).
  - `Season` & `SeasonRewardTier` & `UserSeasonProgress` (Battle Pass sezon sistemi).
  - `Friendship` & `PlayerReport` (Arkadaşlık ve oyuncu şikayet mekanizması).
  - `InAppNotification` (Uygulama içi bildirimler).
* **Value Object:** `Username` (Özel karakter filtreleme, ayrılmış isim kontrolü: admin, root vb.).
* **Tasarım Kalıpları:**
  - `StateMachine<TState, TTrigger>`: Lobi ve maç durum geçişleri (`Lobby -> Starting -> InProgress -> Finished`).
  - `IGamePolicy<T>`: İş kuralı denetleyicileri.
  - `ISpecification<T>`: Sorgu spesifikasyonları.

### 1.4 Fireman.Application (Uygulama & Use Case Katmanı)
* **Servisler:**
  - `AuthService`, `UserService`, `CharacterService`, `InventoryService`, `MissionService`, `MatchService`, `OfflineSyncService`, `LeaderboardService`, `AdminService`, `SocialService`, `WalletService`, `SeasonService`, `NotificationService`.
* **Bağımsız Game Policies (Tek Dosya Kuralı):**
  - `CanJoinMatchPolicy`: Oda doluluk, oyuncu ban durumu ve lobi kontrolü.
  - `CanBuyItemPolicy`: Cüzdan bakiye ve eşya satın alınabilirlik kontrolü.
  - `CanEquipItemPolicy`: Envanter sahipliği ve slot uyumluluğu kontrolü.
  - `CanStartMissionPolicy`: Seviye gereksinimi ve aktif görev kontrolü.
* **Server-Authoritative Anti-Cheat Doğrulama Motoru (`AntiCheatValidationService`):**
  - Hareket analizi: $\Delta t \le 0$ manipülasyon engeli, Öklid mesafe/hız hesabı ($v = d / \Delta t$).
  - `MaxAllowedSpeed` (16 m/s) ve `TeleportThreshold` (40 m/s) ile Speedhack ve Işınlanma tespiti.
  - Skor analizi: Zaman başına anormal skor artışı ve kurtarma başına maksimum puan sınırı.
  - Nozul kontrolü: Saniyedeki su deşarj kapasitesini aşan sonsuz su hilelerinin tespiti.
  - Otomatik ceza: Kritik ihlallerde kullanıcıyı `Banned` statüsüne alma, `AntiCheatLog` üretme ve `AntiCheatViolationDetectedEvent` yayımlama.
* **Olay Güdümlü Altyapı (Event Bus & Isolation):**
  - Hata izolasyonlu decoupled event handler'lar.
  - `CacheInvalidationHandlers`: Karakter ve liderlik tablosu cache temizleme.

### 1.5 Fireman.Infrastructure (Altyapı & Veri Katmanı)
* **Entity Framework Core & PostgreSQL:**
  - `Npgsql.EntityFrameworkCore.PostgreSQL` provider'ı eklendi.
  - `FiremanDbContext` oluşturuldu.
  - 15 ayrı `IEntityTypeConfiguration<T>` sınıfı yazıldı (`UserConfiguration`, `CharacterConfiguration`, `MatchConfiguration` vb.).
* **Güvenlik & Yetkilendirme:**
  - PBKDF2 SHA-256 tabanlı `PasswordHasher`.
  - JWT Access Token & Refresh Token üreten `JwtTokenService`.
* **Arka Plan Servisleri:**
  - `OutboxProcessorBackgroundService`: Outbox tablosundaki kuyruk olaylarını asenkron işleyen `IHostedService`.
  - `IdempotencyService`: Ağ kopmalarında mükerrer istekleri engelleyen benzersiz anahtar servisi.

### 1.6 Fireman.Api (REST & SignalR)
* **Controller'lar:** `AuthController`, `UsersController`, `CharactersController`, `InventoryController`, `MissionsController`, `MatchesController`, `LeaderboardController`, `OfflineSyncController`, `AdminController`, `SocialController`, `FeatureFlagsController`, `WalletController`, `SeasonsController`, `NotificationsController`.
* **SignalR Hub:** `MatchHub` (`/hubs/match`) - Gerçek zamanlı oyuncu hareketi, su sıkma, lobi hazır durumu ve Anti-Cheat canlı uyarıları.
* **Ara Yazılımlar (Middleware):**
  - `CorrelationIdMiddleware`
  - `GlobalExceptionHandlingMiddleware`
  - `RateLimitingMiddleware`
  - `CORS Policy`: Mobil ve web istemcilerinin SignalR/REST erişimi için yapılandırıldı.
  - `HealthChecks`: `/health` uç noktası.

---

## 🎮 2. Oyun Mekanikleri: "Playing with Fire 2" (Bomberman)

Kullanıcının ilettiği referans görsele uygun olarak geliştirilen tam oyun motoru:

1. **Izgara (Grid) Sahası:**
   - 11 Sütun $\times$ 9 Satır hücre yapısı.
   - Dış sınırlar ve çift koordinatlarda kırılmaz sabit taş bloklar (`Wall`).
   - Labirent içinde kırılabilir kırmızı ahşap/metal variller (`Barrel`).
   - Oyuncunun ve rakiplerin doğduğu 4 köşe hücre açık ve korumalı.

2. **Bomba & Patlama Mekaniği:**
   - Her oyuncu başlangıçta **1 bomba** hakkına sahiptir.
   - Bırakılan bomba ~2.2 saniyelik fitil geri sayımının ardından haç ($+$) şeklinde 4 yöne (Yukarı, Aşağı, Sol, Sağ) patlar.
   - Patlama sabit taş duvarlarda durur.
   - Kırmızı varile çarparsa varili patlatır, o yöndeki yayılmayı sonlandırır ve içinden güçlendirici düşürür.
   - Diğer bombalarla zincirleme patlama (chain reaction) tetikler.
   - Patlama menzilinde kalan oyuncu ve botlar can kaybeder.

3. **Düşen Güçlendiriciler (Power-Up Asset'ler):**
   - ⚡ **Şimşek (Lightning):** Bombaların patlama menzilini/şiddetini $+1$ kare artırır.
   - 👟 **Ayakkabı (Shoes):** Karakterin hareket hızını $+0.25x$ oranında yükseltir.
   - 💣 **Bomba (Extra Bomb):** Aynı anda bırakılabilecek maksimum bomba sayısını $+1$ artırır.
   - 🔧 **Tamir (Heal):** Karakterin canını $+25\text{ HP}$ iyileştirir.
   - **Toplama:** Oyuncu asset'in bulunduğu karenin üstüne adım attığında otomatik olarak toplanır.

---

## 📱 3. Flutter Mobil İstemcisi (`client/fireman_flutter/`)

* **Teknoloji:** Flutter 3.41, Dart 3.11, Provider (MVVM), SharedPreferences.
* **Durum:** `flutter analyze` ile **0 Hata, 0 Uyarı**.

### 3.1 Akış ve Ekranlar
1. **Animasyonlu Onboarding Ekranı (`onboarding_screen.dart`):**
   - Her oyun açılışında başlar.
   - Tanıtım ve hikaye metinleri sırayla ekrana gelir.
   - **Her yeni yazı gelmeden önce önceki metin karararak (Fade-Out / Blackout) kaybolur**, ardından sıradaki metin belirir (Fade-In).
   - Metin akışı bitince **Kullanıcı Adı Belirleme** alanı açılır.
   - Oyuncu adını girip "Arenaya Giriş Yap" dediğinde profil yerel hafızaya kaydedilir ve Ana Menüye geçilir.

2. **Gelişmiş Ana Menü Ekranı (`main_menu_screen.dart`):**
   - **Sol Taraf (İstatistikler):**
     - Kazanılan Puan (🪙 Total Score)
     - Oynanan Oyun Sayısı
     - Kazanılan Oyun Sayısı
     - Mevcut Sıralama (#Rank)
   - **Sağ Taraf (Nefes Alan Canlı Karakter):**
     - `AnimationController` ile çalışan `sin(t)` tabanlı **idle breathing & swaying (nefes alma ve sağa-sola salınım)** animasyonu.
   - **Alt Bölüm (6 Seçenek Menüsü):**
     - 🎮 **TEK OYNA (Offline):** Tıklandığında diyalog açılır; kullanıcı **2 Kişilik (1v1 Bot)**, **3 Kişilik (1v2 Bot)** veya **4 Kişilik (1v3 Bot)** modlarından birini seçer!
     - 🌐 **ONLINE OYNA:** 4 kişilik eşleşme ve lobi ekranı (`LobbyScreen`).
     - 🏆 **TABLO:** Liderlik sıralaması penceresi.
     - 🧑‍🚒 **DÜZENLE:** Karakter seviye/XP kartı, kuşanılmış teçhizat ve kask/ceket gardırobu (`CharacterScreen`).
     - ⚙️ **AYARLAR:** Ses, titreşim ve 60FPS ayar penceresi.
     - 🚪 **ÇIKIŞ:** Çıkış bildirimi.

3. **Oyun Ekranı (`gameplay_screen.dart`):**
   - `BombermanPainter` CustomPaint ile çizilen gerçek zamanlı arena.
   - Seçilen mod sayısına göre arenada yapay zekaya sahip botlar (Mor, Yeşil, Turuncu İtfaiyeciler) yer alır.
   - Botlar bağımsız olarak boşluklarda hareket eder ve varillerin yanına bomba bırakır.
   - Dokunmatik D-Pad yön butonları + büyük 💣 **BOMBA** butonu.
   - Fiziksel klavye desteği (`W, A, S, D` / `Yön Tuşları` + `Space`).

---

## 💻 4. Web Kontrol & Simülatör Paneli (`server/Fireman.Api/wwwroot/`)

* Backend API'nin statik dosya sunucusu üzerinden çalışan interaktif kontrol merkezi:
  - **HTML5 Canvas Oyun Alanı:** Playing with Fire 2 ızgarasını, patlamaları ve varilleri web tarayıcısında oynanabilir kılar.
  - **SignalR Entegrasyonu:** Gerçek zamanlı soket üzerinden hareket ve yangın aksiyonu test aracı.
  - **Anti-Cheat Simülatörü:** Hız hilesi ve ışınlanma paketleri göndererek sunucunun ihlal yakalama ve otomatik banlama tepkisini canlı test etme butonları.
  - **Görevler & Lider Tablosu:** API üzerinden canlı veri alışverişi.

---

## 📊 5. Test ve Kalite Durumu
* **Derleme:**
  - .NET Solution (`Fireman.slnx`): 10 proje **0 Hata** ile derlenmektedir.
  - Flutter Mobile (`client/fireman_flutter`): `flutter analyze` **0 Hata, 0 Uyarı**.
* **Güvenlik ve İzolasyon:**
  - Tüm event handler'lar izole edilmiştir.
  - Password hash'leme ve JWT token doğrulama test edilmiştir.
  - Rate Limiting ve Anti-Cheat politikaları devrededir.
* **Git Durumu:**
  - Tüm değişiklikler `master` branch'inde temizlenmiş ve commitlenerek GitHub uzak deposuna pushlanmıştır.

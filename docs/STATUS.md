# 📊 Fireman Sistem Durumu (Status Matrix)

> **Güncelleme Tarihi:** 2026-10-10  
> **Tanımlar:**  
> **✅ Doğrulandı:** Kod var + otomatik test var + ortamda çalışıyor + metrik ölçülüyor  
> **🟡 Kısmi:** Kod var, ama entegrasyon/test/ölçüm eksik  
> **📄 Yalnızca doküman/iskelet:** Tasarım, DTO veya ADR var; çalışan uygulama yok  
> **❌ Yok:** Henüz başlanmadı

---

| Bileşen | Durum | Mevcut Kod / Kanıt Bağlantısı | Kalan Eksik / Not |
|---|:---:|---|---|
| **Fireman.GameCore** | ✅ | [MatchSimulation.cs](../server/Fireman.GameCore/Simulation/MatchSimulation.cs)<br/>[MatchSimulationTests.cs](../tests/Fireman.UnitTests/GameCore/MatchSimulationTests.cs)<br/>[SimulationBenchmarkTests.cs](../tests/Fireman.UnitTests/GameCore/SimulationBenchmarkTests.cs) | 30Hz döngü, BFS patlama, FNV-1a hash, determinizm testi ve <1ms benchmark testi doğrulandı. |
| **Replay & Determinizm Doğrulama** | ✅ | [MatchReplay.cs](../server/Fireman.GameCore/Replay/MatchReplay.cs)<br/>[ReplayValidatorTests.cs](../tests/Fireman.UnitTests/GameCore/ReplayValidatorTests.cs) | Bit-bit deterministik replay kaydı ve `ReplayValidator` doğrulama testleri %100 yeşil. |
| **MatchHost (Aktör & Tick Döngüsü)** | ✅ | [MatchHostManager.cs](../server/Fireman.Api/Hubs/MatchHostManager.cs) | Lock-free `Channel<PlayerInputDto>`, Stopwatch drift telafisi (`targetTime = start + n*dt`) ve 20Hz snapshot yayını devrede. |
| **Fireman.LoadBot (Yük & Doğrulama)** | ✅ | [Program.cs](../tools/Fireman.LoadBot/Program.cs)<br/>[Fireman.LoadBot.csproj](../tools/Fireman.LoadBot/Fireman.LoadBot.csproj) | 4-400 sanal istemciyi SignalR MessagePack ile bağlayıp 30Hz girdi basan ve WorldHash eşitliğini denetleyen konsol aracı hazır. |
| **MatchHub ↔ GameCore Bağlantısı** | ✅ | [MatchHub.cs](../server/Fireman.Api/Hubs/MatchHub.cs) | `SendPlayerInput` ve `JoinMatch` doğrudan `MatchHostManager` aktörüne bağlı. |
| **Flutter Online Oyun** | 🟡 | [prediction_engine.dart](../client/fireman_flutter/lib/services/prediction_engine.dart)<br/>[lobby_screen.dart](../client/fireman_flutter/lib/views/lobby_screen.dart) | Yerel prediction/reconciliation motoru ve lobi arenaya geçiş butonu var. Canlı soket akışı bağlanacak. |
| **Prediction / Reconciliation** | 🟡 | [prediction_engine.dart](../client/fireman_flutter/lib/services/prediction_engine.dart) | Seq tabanlı yerel hareket ve sunucu onayında geri sarma/tekrar uygulama motoru yazıldı. |
| **Matchmaking & Lobi** | 🟡 | [lobby_screen.dart](../client/fireman_flutter/lib/views/lobby_screen.dart)<br/>[match_viewmodel.dart](../client/fireman_flutter/lib/viewmodels/match_viewmodel.dart) | Lobi oluşturma/katılma akışı ve oda durumu var. Redis sorted set kuyruğu bağlanacak. |
| **PostgreSQL & EF Core Şeması** | ✅ | [001_InitialCreate.sql](../server/Fireman.Infrastructure/Persistence/Migrations/001_InitialCreate.sql)<br/>[FiremanDbContext.cs](../server/Fireman.Infrastructure/Persistence/FiremanDbContext.cs)<br/>[SchemaModelValidationTests.cs](../tests/Fireman.IntegrationTests/Persistence/SchemaModelValidationTests.cs) | Klanlar dahil 17 entity, SQL şeması, EF konfigürasyonları ve model doğrulama entegrasyon testi aktif. |
| **Anti-Cheat v2** | 🟡 | [AntiCheatValidationService.cs](../server/Fireman.Application/AntiCheat/AntiCheatValidationService.cs) | Grid sub-tile hız ve sıra no denetimi aktif. Replay validator servisle bağlanacak. |
| **IAP Sunucu Doğrulama** | 🟡 | [IapReceiptValidationService.cs](../server/Fireman.Infrastructure/Services/IapReceiptValidationService.cs) | Google Play ve Apple App Store makbuz doğrulama servisi ve audit loglaması yazıldı. |
| **RemoteConfig** | 🟡 | [balance.v1.json](../server/Fireman.Api/Config/balance.v1.json)<br/>[RemoteConfigService.cs](../server/Fireman.Infrastructure/Services/RemoteConfigService.cs) | Sürümlü JSON ve `/api/v1/config/{key}` uç noktası canlı. |
| **Klan / Sosyal** | ✅ | [Clan.cs](../server/Fireman.Domain/Social/Clan.cs)<br/>[SocialHub.cs](../server/Fireman.Api/Hubs/SocialHub.cs)<br/>[ClanConfiguration.cs](../server/Fireman.Infrastructure/Persistence/Configurations/ClanConfiguration.cs) | Domain varlıkları, SignalR klan kanalları, EF Core ve PostgreSQL şema tabloları tamamlandı. |
| **GDPR / Hesap Silme** | 🟡 | [AuthAndUsersControllers.cs](../server/Fireman.Api/Controllers/AuthAndUsersControllers.cs)<br/>[gdpr-kvkk-compliance.md](compliance/gdpr-kvkk-compliance.md) | `/me/export` ve `/me` hesap silme uç noktaları kodlandı. |
| **SRE, SLO & Alarmlar** | 🟡 | [sre-incident-runbooks.md](runbooks/sre-incident-runbooks.md)<br/>[FiremanMetrics.cs](../server/Fireman.Infrastructure/Monitoring/FiremanMetrics.cs) | 4 runbook ve OTel metrikleri yazıldı. |
| **ADR Hijyeni (0001–0010)** | ✅ | [docs/adr/](adr/) | ADR-0001'den ADR-0010'a kadar tüm mimari kararlar eksiksiz belgelendi. |

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
| **Fireman.GameCore** | 🟡 | [MatchSimulation.cs](../server/Fireman.GameCore/Simulation/MatchSimulation.cs)<br/>[MatchSimulationTests.cs](../tests/Fireman.UnitTests/GameCore/MatchSimulationTests.cs)<br/>[SimulationBenchmarkTests.cs](../tests/Fireman.UnitTests/GameCore/SimulationBenchmarkTests.cs) | 30Hz döngü, BFS patlama, FNV-1a hash, determinizm testi ve <1ms benchmark testi var. Mutation test (Stryker) eksik. |
| **MatchHost (Aktör & Tick Döngüsü)** | 🟡 | [MatchHostManager.cs](../server/Fireman.Api/Hubs/MatchHostManager.cs) | Maç oturumu başına 30Hz tick döngüsü ve 20Hz snapshot yayını yazıldı. `Channel<PlayerInput>` drift düzeltmesi eklenmeli. |
| **MatchHub ↔ GameCore Bağlantısı** | 🟡 | [MatchHub.cs](../server/Fireman.Api/Hubs/MatchHub.cs) | `SendPlayerInput` doğrudan `MatchHostManager` kuyruğuna besleniyor. `RequestFullSnapshot` RPC'si eklenecek. |
| **Flutter Online Oyun** | 🟡 | [prediction_engine.dart](../client/fireman_flutter/lib/services/prediction_engine.dart)<br/>[lobby_screen.dart](../client/fireman_flutter/lib/views/lobby_screen.dart) | Yerel prediction/reconciliation motoru ve lobi arenaya geçiş butonu var. Gerçek SignalR soket dinleyicisi tam bağlanacak. |
| **Prediction / Reconciliation** | 🟡 | [prediction_engine.dart](../client/fireman_flutter/lib/services/prediction_engine.dart) | Seq tabanlı yerel hareket ve sunucu onayında geri sarma/tekrar uygulama formülü yazıldı. Golden vektör testi eksik. |
| **Matchmaking & Lobi** | 🟡 | [lobby_screen.dart](../client/fireman_flutter/lib/views/lobby_screen.dart)<br/>[match_viewmodel.dart](../client/fireman_flutter/lib/viewmodels/match_viewmodel.dart) | Lobi oluşturma/katılma akışı ve oda durumu var. Redis sorted set kuyruğu ve OpenSkill FFA kalıcılığı eksik. |
| **PostgreSQL Şeması** | 🟡 | [001_InitialCreate.sql](../server/Fireman.Infrastructure/Persistence/Migrations/001_InitialCreate.sql)<br/>[FiremanDbContext.cs](../server/Fireman.Infrastructure/Persistence/FiremanDbContext.cs) | 15 entity konfigürasyonu ve SQL şeması var. EF Core Migration tek doğruluk kaynağı kararı (ADR) ve drift testi eksik. |
| **Redis Kullanımı** | 📄 | [docker-compose.yml](../docker-compose.yml) | Konteyner ve connection string tanımlı; SignalR backplane ve liderlik ZADD henüz aktif edilmedi. |
| **Anti-Cheat v2** | 🟡 | [AntiCheatValidationService.cs](../server/Fireman.Application/AntiCheat/AntiCheatValidationService.cs) | Grid sub-tile hız ve sıra no denetimi aktif. Replay doğrulama servisi henüz bağlanmadı. |
| **Çok Bölge** | 📄 | [0010-multi-region-control-data-plane.md](adr/0010-multi-region-control-data-plane.md) | ADR dokümanı var; canlı dağıtım Faz 5'e ertelendi. |
| **SRE, SLO & Alarmlar** | 🟡 | [sre-incident-runbooks.md](runbooks/sre-incident-runbooks.md)<br/>[FiremanMetrics.cs](../server/Fireman.Infrastructure/Monitoring/FiremanMetrics.cs) | 4 runbook ve OTel metrikleri yazıldı; Prometheus/Grafana panosu bağlanacak. |
| **IAP Sunucu Doğrulama** | 📄 | [IapContracts.cs](../server/Fireman.Contracts/Economy/IapContracts.cs) | Sözleşmeler var; Google Play/Apple StoreKit HTTP doğrulama servisi yazılacak. |
| **RemoteConfig** | 🟡 | [balance.v1.json](../server/Fireman.Api/Config/balance.v1.json)<br/>[RemoteConfigService.cs](../server/Fireman.Infrastructure/Services/RemoteConfigService.cs) | Sürümlü JSON ve `/api/v1/config/{key}` uç noktası canlı. DB kalıcılığı ve staged rollout eklenecek. |
| **Klan / Sosyal** | 🟡 | [Clan.cs](../server/Fireman.Domain/Social/Clan.cs)<br/>[SocialHub.cs](../server/Fireman.Api/Hubs/SocialHub.cs) | Domain varlıkları ve SignalR klan kanalları yazıldı; EF migration'a eklenecek. |
| **GDPR / Hesap Silme** | 🟡 | [AuthAndUsersControllers.cs](../server/Fireman.Api/Controllers/AuthAndUsersControllers.cs)<br/>[gdpr-kvkk-compliance.md](compliance/gdpr-kvkk-compliance.md) | `/me/export` ve `/me` hesap silme uç noktaları kodlandı; uçtan uca testi yapılacak. |
| **CI / CD Hatları** | 🟡 | [backend-ci.yml](../.github/workflows/backend-ci.yml)<br/>[mobile-ci.yml](../.github/workflows/mobile-ci.yml) | GitHub Actions derleme ve testleri çalışıyor; kapsam eşiği kapısı eklenecek. |
| **ADR Hijyeni (0001–0009)** | ❌ | — | ADR-0010 tek başına duruyor; eksik 0001–0009 ADR'leri yazılacak. |

# ADR-0005: Modüler Monolit ve Maç Başına Aktör (Actor Loop) Modeli

## Durum
Kabul Edildi

## Bağlam
Gerçek zamanlı çok oyunculu oyunlarda her maç bağımsız bir simülasyon durumuna, sabit tick döngüsüne (30Hz) ve ayrık girdi kuyruğuna ihtiyaç duyar. Dağınık mikroservis mimarisi bu aşamada aşırı ağ gecikmesi, dağıtık kilitlenme karmaşıklığı ve operasyonel maliyet getirir.

## Karar
1. Backend mimarisi net sınırlarla ayrılmış tek bir modüler monolit (`Fireman.Api`, `Fireman.Application`, `Fireman.Domain`, `Fireman.Infrastructure`, `Fireman.GameCore`) olarak yapılandırılmıştır.
2. Her aktif maç (`ActiveMatchSession`), Aktör Modeli benzeri izole bir yaşam döngüsüne sahiptir:
   - Girdiler lock-free `Channel<PlayerInputDto>` ile aktöre akar.
   - 30Hz simülasyon döngüsü drift telafisi (`Stopwatch` tabanlı hedef zaman hesabı) ile çalışır.
   - Snapshot yayınları (~20Hz) SignalR MessagePack gruplarına aktör içinden yönlendirilir.

## Sonuçlar
- **Olumlu:** Sıfır thread çekişmesi (lock contention), deterministik simülasyon izolasyonu, düşük bellek ayak izi.
- **Olumsuz:** Tek sunucu çöküşü o sunucudaki tüm aktif maçları etkiler (Faz 3 çok bölgeli orkestrasyon ile hafifletilir).

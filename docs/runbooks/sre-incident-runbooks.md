# Fireman SRE Runbook: Acil Müdahale ve Operasyon Kılavuzu

> **Hedef:** Faz 3 WP15 Güvenilirlik Mühendisliği kapsamında sistem arızalarında ilk 15 dakikada uygulanacak kesin adımlar.

---

## 1. Servis Seviyesi Hedefleri (SLO) ve Eşikler

| Metrik (SLI) | Hedef (SLO) | Uyarı Eşiği | Müdahale Seviyesi |
|---|---|---|---|
| **API Availability** | ≥ %99.9 / ay | < %99.5 (5 dk) | SEV-1 (Kritik) |
| **Simülasyon Tick Süresi (p99)** | < 10 ms | > 15 ms (3 dk) | SEV-2 (Yüksek) |
| **Maç Bulma Başarısı (60s)** | ≥ %98 | < %90 (5 dk) | SEV-1 (Kritik) |
| **Maç Kesinti Oranı** | < %0.5 | > %1.0 (5 dk) | SEV-1 (Kritik) |
| **Kimlik Doğrulama / Login p95** | < 400 ms | > 800 ms (5 dk) | SEV-2 (Yüksek) |

---

## 2. Acil Müdahale Senaryoları (Runbooks)

### RUNBOOK-01: Veritabanı (PostgreSQL) Failover / Yanıt Vermeme
1. **Belirti:** API uç noktaları `500 Internal Server Error` veya `NpgsqlException: Connection timeout` veriyor.
2. **Teşhis:**
   ```bash
   docker compose exec postgres pg_isready -U fireman -d fireman_db
   ```
3. **Müdahale:**
   - Birincil konteyneri yeniden başlat: `docker compose restart postgres`
   - Bağlantı havuzu tükenmişse `pg_stat_activity` üzerindeki kilitli sorguları sonlandır:
     ```sql
     SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE state = 'active' AND query_start < now() - interval '2 minutes';
     ```

### RUNBOOK-02: Redis Bellek Taşması veya Çökmesi
1. **Belirti:** SignalR oyuncu grupları mesaj iletmiyor, lobiler kilitleniyor, önbellek okumaları başarısız.
2. **Teşhis:**
   ```bash
   docker compose exec redis redis-cli info memory
   ```
3. **Müdahale:**
   - Bellek tahliyesini zorla: `redis-cli config set maxmemory-policy allkeys-lru`
   - Geçici lobi oturum anahtarlarını temizle: `redis-cli keys "fireman:lobby:*" | xargs redis-cli del`

### RUNBOOK-03: Simülasyon Tick Aşımı (Tick Overrun > 33.3ms)
1. **Belirti:** Oyuncular "rubber-banding" ve gecikmeli patlama raporluyor.
2. **Teşhis:** Grafana `fireman_tick_duration_ms` grafiğini kontrol et.
3. **Müdahale:**
   - Düğüm başına aktif maç sayısını KEDA üzerinden düşür (Scaling factor artır).
   - Ağır BFS zincirleme patlaması olan anormal maçları güvenli şekilde sonlandır.

### RUNBOOK-04: Sahte IAP / Çift Harcama Saldırısı
1. **Belirti:** Kısa sürede anormal altın/elmas artışı ve negatif bakiye denemeleri.
2. **Teşhis:** `CurrencyLedgerEntries` tablosunda mükerrer `ReferenceId` kontrolü yap.
3. **Müdahale:**
   - Şüpheli kullanıcıyı otomatik askıya al: `User.Status = Banned`.
   - Feature flag üzerinden IAP mağazasını geçici olarak kapat (`FeatureFlag: StoreIapEnabled = false`).

# Fireman • Faz 3 Önceliklendirme Matrisi ve Uygulama Planı

> Bu doküman, `Fireman_Faz3_Lansman_Olcekleme_LiveOps.md` yol haritasında yer alan 12 iş paketinin iş etkisi (Impact), teknik risk ve öncelik (P0/P1/P2) puanlamasını ve sprint uygulama sırasını belirler.

---

## 1. Faz 3 İş Paketi Önceliklendirme Matrisi

| Sıra | İş Paketi | Kapsam | Öncelik | Teknik Risk | İş Değeri / Etki | Sprint |
|---|---|---|:---:|:---:|:---:|:---:|
| **1** | **WP15** | **Güvenilirlik (SRE), SLO & Runbook'lar** | 🔴 **P0** | Orta | Kritik (Kesintisiz Hizmet) | S11 |
| **2** | **WP14** | **Çok Bölgeli (Multi-Region) Mimari & Kapasite Modeli** | 🔴 **P0** | Yüksek | Kritik (<80ms RTT Küresel) | S11 - S13 |
| **3** | **WP21** | **Güven & Güvenlik, Hesap Güvenliği, Anti-Cheat v3** | 🔴 **P0** | Yüksek | Kritik (Adil Rekabet) | S18 |
| **4** | **WP18** | **LiveOps Platformu & Sürümlü Remote Config** | 🟠 **P1** | Düşük | Çok Yüksek (İçerik Yönetimi) | S15 |
| **5** | **WP19** | **Ekonomi Tasarımı & Sunucu Taraflı IAP Doğrulama** | 🟠 **P1** | Orta | Çok Yüksek (Monetizasyon) | S14 |
| **6** | **WP20** | **Analytics Olay Şeması & Veri Hattı (A/B Test)** | 🟠 **P1** | Orta | Yüksek (Veri Güdümlü Büyüme) | S14 |
| **7** | **WP16** | **Dereceli Lig (MMR), Turnuva & Replay İzleyici** | 🟠 **P1** | Orta | Yüksek (Tutundurma & E-Spor) | S16 |
| **8** | **WP17** | **Sosyal Ekosistem (Klan, Parti, Denetimli Sohbet)** | 🟠 **P1** | Düşük | Yüksek (Viral Büyüme & Kabile) | S17 |
| **9** | **WP24** | **Hukuk, KVKK/GDPR, Çocuk Güvenliği & Mağaza İncelemesi** | 🟠 **P1** | Düşük | Yasal Zorunluluk | S11 |
| **10** | **WP25** | **Soft Launch, Edinim (UA) & ASO Kampanyası** | 🟠 **P1** | Düşük | Lansman Başarısı | S19 - S20 |
| **11** | **WP22** | **Platform Genişlemesi (Gamepad, Tablet, 120Hz)** | 🟡 **P2** | Düşük | Orta (Erişilebilirlik) | S19 |
| **12** | **WP23** | **UGC Harita Editörü & Genişleme Modları (2v2)** | 🟡 **P2** | Orta | Orta (Uzun Vadeli İçerik) | S21+ |

---

## 2. İlk Uygulama Bloğu (P0 & Hızlı Kazanım P1'ler)

1. **SLO / SLI Metrikleri & Sağlık Kontrolleri (WP15):**
   - API uptime (%99.9), Tick p99 (<10ms), Login p95 (<400ms) için Prometheus/Grafana sayaçları.
2. **Ekonomi Faucet / Sink Modeli & Sunucu IAP Doğrulama İskeleti (WP19):**
   - Google Play Billing ve Apple StoreKit 2 sunucu makbuz doğrulama sözleşmesi.
   - Çift harcama engelleme (`xmin` / idempotency).
3. **Analytics Olay Şeması (Event Schema Registry - WP20):**
   - `match_start`, `match_end`, `powerup_collected`, `purchase_completed`, `cheat_flagged` telemetri olayları.

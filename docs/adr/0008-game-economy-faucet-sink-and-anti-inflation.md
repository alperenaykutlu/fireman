# ADR-0008: Oyun İçi Ekonomi Musluk/Gider (Faucet/Sink) Dengesi ve Anti-Enflasyon

## Durum
Kabul Edildi

## Bağlam
Oynaması ücretsiz (F2P) oyunlarda para birimlerinin kontrolsüz basılması hiperenflasyona, kozmetik ve yükseltmelerin değerini yitirmesine ve oyuncu kaybına (churn) yol açar.

## Karar
1. **Çift Para Birimi Mimarisi:**
   - **Soft Currency (Altın):** Maç sonu ödülleri, günlük görevler (Musluk / Faucet). Kullanım yerleri: Karakter yükseltme, temel kozmetikler, klan bağışları (Gider / Sink).
   - **Hard Currency (Elmas):** Yalnızca IAP (mağaza satın alımı) ve sezon sonu elit ödülleri. Kullanım yerleri: Battle Pass, özel temalı kostümler.
2. **Defter Tabanlı (Ledger-Based) Kalıcılık:**
   - Bakiye güncellemeleri yalnızca doğrudan bakiye arttırıp azaltmakla kalmaz; `CurrencyLedgerEntry` tablosuna çift taraflı denetim iziyle (transaction reference, reason) işlenir.
3. **Dinamik Faucet/Sink Kontrolü:**
   - Ödül katsayıları `RemoteConfigService` ve `balance.v1.json` üzerinden sunucu tarafında anlık ayarlanabilir.

## Sonuçlar
- **Olumlu:** Hileli bakiye üretimleri hemen tespit edilir, ekonomi enflasyonu canlı parametrelerle kontrol altında tutulur.
- **Olumsuz:** Ledger tablosu yüksek maç hacminde hızlı büyür (partisyonlama ve arşivleme gerektirir).

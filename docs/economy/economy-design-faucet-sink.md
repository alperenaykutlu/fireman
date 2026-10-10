# Fireman Oyun Ekonomisi Tasarım Dokümanı (Faucet & Sink Modeli)

> **Amaç:** WP19 kapsamında enflasyonsuz, adil, dengeli ve pay-to-win içermeyen sürdürülebilir bir mobil ekonomi kurmak.

---

## 1. Para Birimleri Mimarisi

```mermaid
graph TD
    subgraph Faucets["💧 Kaynaklar (Musluklar)"]
        M_WIN["Maç Galibiyeti (+150 Altın)"]
        M_PLAY["Maç Katılımı (+30 Altın)"]
        M_KILL["Rakip Eleme (+25 Altın)"]
        DAILY["Günlük Görevler (+200 Altın)"]
        BP_FREE["Battle Pass Ücretsiz (+500 Altın)"]
        IAP["IAP Mağazası (Elmas Satın Alımı)"]
    end

    subgraph Currencies["💰 Para Birimleri"]
        GOLD["🪙 ALTIN (Yumuşak Para)<br/>Oynayarak Kazanılır"]
        GEMS["💎 ELMAS (Sert Para)<br/>IAP ve Sezonluk Başarı"]
    end

    subgraph Sinks["🕳️ Giderler (Harcama Noktaları)"]
        UPGRADE["Karakter/Kostüm Seviye Yükseltme"]
        SHOP_COSMETIC["Kozmetik Mağaza (Kask, Alev Efekti)"]
        BP_PREMIUM["Premium Battle Pass (500 Elmas)"]
        NAME_CHANGE["İsim Değiştirme (100 Elmas)"]
        TOURNAMENT_FEE["Turnuva Katılım Bileti"]
    end

    M_WIN & M_PLAY & M_KILL & DAILY & BP_FREE --> GOLD
    IAP --> GEMS

    GOLD --> UPGRADE & SHOP_COSMETIC & TOURNAMENT_FEE
    GEMS --> BP_PREMIUM & NAME_CHANGE & SHOP_COSMETIC
```

---

## 2. Denge Kuralları ve Değişmezler (Invariants)

1. **Pay-to-Win Yasağı:** Altın veya Elmas ile doğrudan oyun içi hız, menzil veya hasar artırıcı avantaj **satın alınamaz**. Güçlendiriciler sadece maç esnasında varil kırarak düşer.
2. **Faucet / Sink Oranı:** 30 günlük oyuncu simülasyonunda harcama / kazanma oranı **%85 - %95** bandında tutulur (hafif pozitif birikim, sıfır hiperenflasyon).
3. **Günlük Altın Üst Sınırı (Cap):** Bir günde maçlardan kazanılabilecek azami altın miktarı 1.500 ile sınırlandırılır (bot/otomasyon suistimaline karşı önlem).

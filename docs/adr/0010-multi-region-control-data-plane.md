# ADR-0010: Çok Bölgeli (Multi-Region) Mimari ve Control/Data Plane Ayrımı

## Durum
Kabul Edildi

## Bağlam
Fireman oyunu, 30 Hz tick hızında deterministik çalışan sunucu otoriter bir 2D grid aksiyon oyunudur. Faz 3 kapsamında küresel 50.000+ eşzamanlı oyuncuya (CCU) ve 12.500+ eşzamanlı maça hizmet verilecektir.
Oyuncuların ping gecikmesini (RTT) < 80 ms seviyesinde tutmak ve tek bir veri merkezinin çökmesi durumunda hizmet sürekliliğini korumak gerekmektedir.

## Karar
Sistem mimarisi net bir şekilde iki düzleme ayrılmıştır:

```
                  ┌──────────────────────────────────────────────┐
                  │          GLOBAL CONTROL PLANE                │
                  │  - Kimlik, Kullanıcı Profili, Cüzdan/Ekonomi │
                  │  - Eşleştirme (Matchmaking), Liderlik Tablosu│
                  │  - Global PostgreSQL (Primary + Replica)     │
                  └──────────────────────┬───────────────────────┘
                                         │ (Outbox / Event Bus)
         ┌───────────────────────────────┼───────────────────────────────┐
         ▼                               ▼                               ▼
┌──────────────────┐            ┌──────────────────┐            ┌──────────────────┐
│ REGION: ME / TR  │            │  REGION: EUROPE  │            │ REGION: N.AMERICA│
│ - Gateway Pool   │            │ - Gateway Pool   │            │ - Gateway Pool   │
│ - Match Host Sim │            │ - Match Host Sim │            │ - Match Host Sim │
│ - Regional Redis │            │ - Regional Redis │            │ - Regional Redis │
└──────────────────┘            └──────────────────┘            └──────────────────┘
```

1. **Global Control Plane:**
   - Kimlik doğrulama, kullanıcı profili, cüzdan işlemleri, sezon/Battle Pass ilerlemesi ve mağaza tek bir küresel veri tabanında (PostgreSQL) tutulur.
   - Matchmaking, oyuncuları ping ölçümlerine (RTT probe) göre en yakın bölgesel Data Plane kümesine yönlendirir.
   - Çift harcama (double spend) riskini önlemek için cüzdan işlemleri yalnızca Control Plane üzerinde `xmin` optimistic concurrency ile yürütülür.

2. **Regional Data Plane (Oyun Bölgeleri: ME/TR, EU, NA):**
   - Her bölgede SignalR Gateway havuzu ve `Fireman.GameCore` simülasyonunu koşturan Match Host Worker havuzları bulunur.
   - Her bölge kendi yerel Redis kümesini oturum, oda yönetimi ve pub/sub iletişimi için kullanır.
   - Maç bittiğinde sonuçlar (skor, XP, altın) güvenli Outbox kuyruğu aracılığıyla Global Control Plane'e iletilir.

## Sonuçlar
- **Avantajlar:** Çok düşük gecikme (< 80 ms), bölge arızalarında < 60 saniyede komşu bölgeye yönlendirme, yüksek yatay ölçeklenebilirlik.
- **Dezavantajlar:** Bölgeler arası ağ gecikmesi nedeniyle maç sonu veri yazmalarının asenkron (Outbox üzerinden) olması gerekir.

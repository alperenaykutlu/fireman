# 🚒 FIREMAN • Faz 4: Entegrasyon, Dikey Dilim ve Üretim Gerçekliği

> **Kapsam:** Faz 2 (otoriter motor) ve Faz 3 (lansman/ölçek/LiveOps) çıktılarının gerçek, çalışan, test edilmiş ve uçtan uca bağlı bir ürüne dönüştürülmesi.
>
> **Neden bu faz?** Faz 1–3 sonunda çekirdek motor, sözleşmeler, dokümanlar ve iskeletler üretildi. Ancak bunların büyük kısmı henüz birbirine bağlı değil ve kanıtlanmış değil. Faz 4, "yazıldı" ile "çalışıyor ve ölçüldü" arasındaki farkı kapatır.
>
> **Ana ilke:** Yeni özellik yok; önce dikey dilim, sonra kanıt. Bu fazın sonunda 4 gerçek oyuncu, gerçek telefonlarda, sunucu otoriter bir maç oynayabilmeli ve bunun metrikleri elimizde olmalıdır.
>
> **Doküman durumu:** Taslak v1.0 • **Önceki:** `Fireman_Faz3_Lansman_Olcekleme_LiveOps.md`

---

## 0. Dürüst Durum Tablosu (Başlangıç Noktası)

Her bileşen şu dört seviyeden biriyle etiketlenir. Raporlarda "tamamlandı" ifadesi yalnızca **✅** seviyesi için kullanılır.

| Seviye | Anlamı |
|---|---|
| **✅ Doğrulandı** | Kod var + otomatik test var + ortamda çalışıyor + metrik ölçülüyor |
| **🟡 Kısmi** | Kod var, ama entegrasyon/test/ölçüm eksik |
| **📄 Yalnızca doküman/iskelet** | Tasarım, DTO veya ADR var; çalışan uygulama yok |
| **❌ Yok** | Henüz başlanmadı |

---

## 1. Faz 4 Hedefleri ve Çıkış Kriterleri

### Hedefler
1. **Dikey dilim:** Telefon → SignalR → MatchHost → GameCore → snapshot → telefon döngüsü.
2. **Kanıt:** Birim/entegrasyon/yük/ağ-koşulu testleriyle ölçülmüş performans.
3. **Tek doğruluk kaynağı:** Şema, sözleşme ve kural setinde çift kaynak yok.
4. **Faz 3 iskeletlerinin gerçeklenmesi:** IAP, RemoteConfig, Klan, SRE alarmları.
5. **Güvenlik ve veri sağlığı:** Token rotasyonu, cihaz doğrulama, hesap silme/dışa aktarma.

### Çıkış Kriterleri (hepsi sağlanmalı)
- [ ] **Demo:** 4 fiziksel cihazda (en az 2 Android + 1 iOS veya emülatör dışı) 10 dakikalık kesintisiz online maç; sunucu hash'i ile istemci snapshot hash'i uyumlu.
- [ ] **Performans:** Tek çekirdekte 4 oyunculu maç tick süresi p99 < 2 ms; 250 eşzamanlı maçta tick p99 < 15 ms.
- [ ] **Ağ:** 100 ms RTT + %5 paket kaybı koşulunda oynanabilir (rubber-banding < %2 tick).
- [ ] **Bant genişliği:** Oyuncu başına indirme < 8 KB/s, yükleme < 2 KB/s.
- [ ] **Test:** GameCore satır kapsamı ≥ %85; backend genel ≥ %70; Flutter çekirdek akışlar ≥ %60; tümü CI'da zorunlu.
- [ ] **Şema:** Tek migration kaynağı; "schema drift" testi yeşil.
- [ ] **Güvenlik:** Pentest ön taraması (OWASP ZAP + manuel) kritik/yüksek bulgu sıfır.
- [ ] **Rapor doğruluğu:** Her ✅ iddiası için bir test, benchmark veya demo kaydı bağlantısı var.

---

## 2. Gap → İş Paketi İzlenebilirlik Matrisi

| Gap | Açıklama | İş Paketi |
|---|---|---|
| G1 | MatchHost / hub–motor bağlantısı yok | WP26 |
| G2 | Flutter online akışı ve netcode eksik | WP26, WP27 |
| G3 | Flutter modernizasyonu yok | WP28 |
| G4 | Matchmaking/lobi/ödül/reconnect yok | WP29 |
| G5 | Şema çift kaynak, Redis kullanımı belirsiz | WP30 |
| G6 | Test/benchmark kanıtı yok | WP31 |
| G7 | Faz 3 çoğunlukla doküman | WP32 |
| G8 | Güvenlik ve hesap işlemleri | WP33 |
| G9 | Davranışsal anti-cheat, replay | WP34 |
| G10 | ADR/dokümantasyon/link hijyeni | WP35 |

---

## 3. İlk 12 Görev (Faz 4 Başlangıcı)

1. [ ] Kodu inceleyerek Bölüm 0 durum tablosunu kesinleştir; `docs/STATUS.md` oluştur.
2. [ ] GameCore için mevcut test sayısı, kapsam ve ilk tick benchmark'ını çıkar (BenchmarkDotNet).
3. [ ] EF migrations ↔ `001_InitialCreate.sql` çift kaynağını kaldırma kararı (ADR) ve drift testi.
4. [ ] MatchHost iskeleti: `Channel<PlayerInput>`, drift düzelten tick döngüsü, `IMatchRegistry`.
5. [ ] MatchHub'ı yeni protokole bağla (`SubmitInput`, `Ready`, `Leave`, `RequestFullSnapshot`).
6. [ ] `Fireman.LoadBot` konsol istemcisi: 4 sanal oyuncu ile tam maç.
7. [ ] Replay kaydı (seed + girdi günlüğü) ve replay doğrulama testi.
8. [ ] Flutter `NetClient` + `OnlineGameController` ilk sürümü (tahminsiz, ham snapshot çizimi).
9. [ ] Ağ koşulu proxy'si (toxiproxy) ve ilk 100 ms/%5 kayıp koşusu.
10. [ ] Eksik ADR'ler 0001–0009'u yaz; raporlardaki mutlak yolları göreli yap.
11. [ ] CI'a kapsam eşiği + benchmark regresyon kontrolü + drift testi ekle.
12. [ ] Ana menüde "Tablo" ve "Düzenle" ayrı rotalarını doğrula/düzelt.

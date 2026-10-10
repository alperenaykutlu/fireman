# Fireman: GDPR / KVKK Veri Envanteri ve Gizlilik Uyumluluk Raporu

> **Kapsam:** WP24 (Hukuk, Uyumluluk ve Mağaza Operasyonu) kapsamında oyuncu verisi yaşam döngüsü, yasal dayanaklar ve unutulma hakkı uygulama rehberi.

---

## 1. Veri Envanteri ve İşleme Amaçları

| Veri Kategorisi | Saklanan Alanlar | Amaç | Yasal Dayanak | Saklama Süresi |
|---|---|---|---|---|
| **Hesap Kimliği** | `UserId`, `Username`, `Email`, `PasswordHash` | Oturum açma, profil yönetimi | Sözleşmenin İfası | Hesap kapatılana kadar |
| **Oynanış Verileri** | `Score`, `Kills`, `Placement`, `GamesPlayed`, `Rank` | Eşleştirme (MMR), liderlik tablosu | Meşru Menfaat | Sezon sonu + 1 yıl (arşiv) |
| **İktisadi / Cüzdan** | `Gold`, `Gems`, `TransactionType`, `ReferenceId` | Satın alım takibi, çift harcama engelleme | Yasal Zorunluluk / Vergi | 10 Yıl (Mali mevzuat) |
| **Güvenlik / Anti-Cheat** | `AntiCheatLog`, `ViolationReason`, `SubTileX/Y` | Hile engelleme, adil rekabet | Meşru Menfaat | 6 Ay |
| **Analitik & Telemetri** | Cihaz modeli, OS sürümü, RTT süresi | Performans optimizasyonu, hata tespiti | Açık Rıza / İstatistik | 90 Gün (Anonimleştirilerek) |

---

## 2. Oyuncu Hakları ve Uygulama Akışı

1. **Veri Dışa Aktarma (Taşınabilirlik):**
   - Oyuncu ayarlarından "Verilerimi İndir" butonuna basıldığında profil, maç geçmişi ve cüzdan hareketleri tek bir şifreli JSON olarak hazırlanır (`GET /api/v1/users/me/export`).
2. **Hesap Silme ve Unutulma Hakkı (Right to be Forgotten):**
   - Oyuncu hesap silme talebi başlattığında hesap hemen dondurulur (`Status = PendingDeletion`).
   - 14 günlük yasal cayma penceresinden sonra `Users`, `Characters`, `Friendships`, `UserMissions` tablolarından kişisel tanımlayıcılar kalıcı olarak silinir; geçmiş maç kayıtlarındaki kullanıcı adı `Anonymous_Player` olarak anonimleştirilir.
3. **Çocuk Verisi (COPPA / GDPR-K):**
   - Onboarding ekranında 13 yaş altı kullanıcılar için serbest metinli sohbet devre dışı bırakılır; sadece varsayılan hızlı ifadeler (Quick Chat / Emote) aktif edilir.

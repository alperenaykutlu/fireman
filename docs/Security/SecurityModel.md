# Güvenlik ve Anti-Cheat Modeli

## 1. Kimlik ve Yetkilendirme
- **Parolalar**: Asla düz metin saklanmaz; PBKDF2 SHA-256 ve 100,000 iterasyonla tuzlanarak hashlenir.
- **JWT**: Kısa ömürlü (2 saat) erişim belirteci, Claims: `uid`, `username`, `role`.
- **Yenileme Belirteçleri (Refresh Token)**: Hashlenmiş saklanır, rotasyon destekler ve iptal (revocation) mekanizmasına sahiptir.

## 2. Server-Authoritative Envanter ve Kozmetik Denetimi
- İstemci `EquipItem(itemId)` isteği gönderdiğinde sunucu kullanıcının envanterini (`InventoryItem`) kontrol eder.
- Sahip olunmayan bir eşya takılmaya çalışılırsa `CanEquipItemPolicy` devreye girer ve işlem reddedilir.

## 3. Offline Senkronizasyon & Anti-Cheat
- Çevrimdışı yapılan işlemler sunucuya senkronize edilirken:
  - Zaman damgası kontrolü yapılır (Gelecek zamanlı manipülasyonlar engellenir).
  - Mantık dışı ödül veya XP talepleri otomatik tespit edilerek `AntiCheatLog` tablosuna yazılır.
  - İdempotent Batch ID ile mükerrer istekler önlenir.

## 4. Ağ ve API Güvenliği
- `X-Correlation-Id`: Her HTTP isteğine benzersiz korelasyon kimliği atanır ve izlenebilirlik sağlanır.
- `RateLimitingMiddleware`: IP bazlı dakikalık istek sınırlaması.
- `GlobalExceptionHandling`: İç sistem hataları istemciye sızdırılmaz, standart hata kodları döndürülür.

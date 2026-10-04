# Fireman API Endpoint Özeti

Tüm endpoint'ler `/api/v1` önekiyle sunulur ve `ApiResponse<T>` sarmalayıcısı kullanır.

## Kimlik Doğrulama (`/api/v1/auth`)
- `POST /register`: Yeni kullanıcı kaydı oluşturur, otomatik karakter ve başlangıç cüzdanı atar.
- `POST /login`: Giriş yapar ve JWT access token ile refresh token döner.
- `POST /refresh-token`: Belirteç yenileme.

## Kullanıcılar (`/api/v1/users`)
- `GET /me`: Aktif kullanıcının profil detayları.
- `PUT /me/username`: Kullanıcı adı güncelleme (Rezerve ad, uzunluk ve normalizasyon kontrolleri).

## Karakter & Özelleştirme (`/api/v1/characters`)
- `GET /me`: Karakter durumu, seviye, DP ve kuşanılmış eşyalar.
- `POST /equip`: Karakter slotuna eşya takma (Sunucu yetkili envanter sahiplik doğrulaması).
- `POST /unequip`: Eşya çıkarma.

## Envanter & Mağaza (`/api/v1/inventory`)
- `GET /shop`: Satın alınabilir eşya katalogu.
- `GET /`: Kullanıcının mevcut envanteri.
- `POST /buy`: Eşya satın alma (Kullanıcı rolüne göre VIP indirim stratejisi, bakiye denetimi, bakiye defteri kaydı).

## Görevler (`/api/v1/missions`)
- `GET /`: Mevcut görev listesi.
- `POST /start`: Göreve başlama.
- `POST /complete`: Görev tamamlama (Skor doğrulaması, rol bazlı ödül stratejisi, seviye atlama, Event-Driven olay yayını).

## Çok Oyunculu Eşleşme (`/api/v1/matches`)
- `POST /`: Yeni oyun odası/maç oluşturma.
- `POST /join`: Mevcut odaya katılma.
- `GET /{id}`: Maç durumu ve oyuncu listesi.
- `POST /score`: Maç skoru ve kurtarma sayısı kaydetme.

## Liderlik Tablosu (`/api/v1/leaderboard`)
- `GET /`: Küresel skor sıralaması (5 dakikalık önbellek destekli).

## Çevrimdışı Senkronizasyon (`/api/v1/offline-sync`)
- `POST /`: Çevrimdışı yapılan eylemleri toplu sunucu doğrulamasından geçirerek işleme.

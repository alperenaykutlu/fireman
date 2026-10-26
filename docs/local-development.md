# Yerel geliştirme ayarları

1. Kök dizindeki `.env.example` dosyasını `.env` adıyla kopyalayın. `.env` Git tarafından yok sayılır.
2. Telefonla API bağlantısı için `API_BASE_URL` değerini bilgisayarın telefonla aynı Wi-Fi ağındaki IPv4 adresine ayarlayın. Bilgisayarın IP adresini `ipconfig` komutundaki Wi-Fi IPv4 satırından bulun.
3. API'yi kök dizinden `./tools/run_api.ps1` ile başlatın. Bu komut `.env` ayarlarını sürece aktarır ve API'yi telefonun erişebileceği `0.0.0.0:5000` adresinde dinletir.
4. Flutter uygulamasını kök dizinden `./tools/run_android.ps1` ile çalıştırın. Komut `.env` içindeki `API_BASE_URL` değerini Flutter'a `--dart-define` olarak aktarır.
5. Yerel Postgres kullanmak isterseniz `docker compose up -d postgres redis` ve ardından `./tools/run_api.ps1 -UsePostgres` komutlarını çalıştırın. Postgres parolası `.env` içindeki `POSTGRES_PASSWORD` ile API bağlantı dizesindeki `ConnectionStrings__DefaultConnection` içinde aynı olmalıdır.

Kök `.env` içindeki RS256 private key, refresh-token pepper, misafir pepper, PostgreSQL/Redis parolaları ve iç servis anahtarı bu çalışma alanı için rastgele üretildi; `.env` Git tarafından yok sayılır. Geliştirme anahtarlarını üretimde yeniden kullanmayın. Üretimde her ortam için ayrı RSA anahtarı ve pepper üretip secret manager üzerinden sağlayın. Anahtar döndürürken yeni private key'i `Jwt__SigningPrivateKeyPkcs8Base64` alanına, eski anahtarın Base64 SubjectPublicKeyInfo public anahtarını da `Jwt__PreviousSigningPublicKeys__0` alanına koyun; eski access token ömrü geçince önceki public key'i kaldırın.

Refresh token'lar kriptografik rastgele üretilir, pepper ile HMAC-SHA256 hash edilerek saklanır, refresh isteğinde tek kullanımlık biçimde döndürülür. Firebase/Firestore için `Firebase__ProjectId` değerini ve Google ile giriş için `GoogleAuth__AllowedAudiences__0` değerini Firebase/Google Cloud projenizin gerçek bilgileriyle doldurun. Google OAuth, Play Integrity, Play Developer API, e-posta, push ve gözlemleme kimlik bilgileri bu depoda bulunmadığı için boş bırakılmıştır. Üretimde eksik JWT signing key/pepper ayarları sunucunun başlamasını engeller.

Ortak, birden fazla ekranda kullanılan bileşenler `client/fireman_flutter/lib/shared/widgets` altında; ekrana/özelliğe özel bileşenler ilgili `views` klasöründe tutulur. Her public `StatelessWidget`/`StatefulWidget` kendi dosyasındadır. Ekranın private `State` sınıfı kendi widget dosyasıyla birlikte kalır.

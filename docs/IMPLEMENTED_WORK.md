# Uygulanan işler

Bu belge, son kod düzenlemelerinde yapılan arayüz bileşeni ayrıştırmasını, ortam ayarlarını ve kimlik doğrulama değişikliklerini özetler. Gizli değerler bilerek bu dosyaya eklenmemiştir.

## Flutter bileşen yapısı

- Ekranlar arasında kullanılabilen genel bileşenler `client/fireman_flutter/lib/shared/widgets/` altına taşındı: kart, seçim çipi, bölüm başlığı, renk seçici, mağaza/güçlendirme kartları ve menü butonları.
- Birden fazla bağımsız widget içeren dosyalar ayrıldı:
  - `GameKeyboardField` ve `GameKeyboard`
  - `FiremanMenuButton` ve `FiremanMiniButton`
  - `AnimatedFirefighterWidget` ve karakter çizim motoru
  - `AmbientEmberOverlay` ve parçacık modeli/çizicisi
  - `DirectionButton` ve `VirtualTouchPad`
  - `DirectChatScreen`, arkadaş listesinden ayrı bir ekran dosyasına taşındı.
- Ekrana özgü bileşenler `views/widgets/` altında tutuldu. Import yolları yeni klasörlere göre güncellendi.

## Ortam ve yerel çalıştırma

- Kök `.env` dosyası oluşturuldu ve Git tarafından yok sayıldığı doğrulandı. Bu yerel dosyada rastgele üretilmiş RS256 özel anahtarı, refresh/guest pepper değerleri, yerel PostgreSQL ve Redis parolaları ve iç servis anahtarı bulunur. Gizli değerler bu Markdown dosyasında veya `.env.example` içinde yer almaz.
- [`.env.example`](../.env.example), gereken ayar adlarını ve açıklamaları içerir. Gerçek Google/Firebase/Play kimlik bilgileri olmadığı için ilgili alanlar şablonda boş bırakılmıştır.
- `tools/run_api.ps1`, `.env` ayarlarını API sürecine aktarır. Geliştirme API'sini `0.0.0.0:5000` üzerinde çalıştırır; `-UsePostgres` seçeneği PostgreSQL sağlayıcısını seçer.
- `tools/run_android.ps1`, `.env` içindeki `API_BASE_URL` değerini Flutter'a `--dart-define` ile aktarır. Bu URL telefonun erişebildiği bilgisayar Wi-Fi IPv4 adresini göstermelidir; IP değişirse `.env` güncellenmelidir.
- Docker Compose PostgreSQL ve Redis parolalarını `.env` üzerinden alacak şekilde güncellendi. Redis parola doğrulaması ve sağlık kontrolü eklendi.
- Yerel çalıştırma ve secret yönetimi notları [`docs/local-development.md`](local-development.md) dosyasına eklendi.

## Kimlik doğrulama ve tokenlar

- Sunucu JWT imzalama algoritması HS256 sabit anahtarından **RS256**'ya geçirildi. Geliştirmede `.env` içindeki Base64 PKCS#8 RSA özel anahtarıyla imzalanır; doğrulama aktif public key ve yapılandırılmış önceki public key'lerle yapılır.
- JWT `Issuer`, `Audience`, `KeyId`, access token süresi, refresh token süresi ve clock-skew toleransı yapılandırmaya taşındı.
- Production/Staging ortamlarında RSA anahtarı veya pepper eksikse/geçersizse uygulama başlangıçta hata verir. Development/Testing ortamında ayar eksikse yalnızca süreç ömrü boyunca geçerli rastgele anahtar ve pepper üretilir.
- Access token ömrü ve API yanıtındaki `ExpiresAt` artık aynı yapılandırılmış süreyi kullanır.
- Refresh token'lar 64 rastgele bayttan Base64URL olarak üretilir. Ham token yerine pepper'lı HMAC-SHA256 hash'i saklanır.
- Refresh token endpoint'i etkinleştirildi: geçerli refresh token doğrulanır, mevcut token iptal edilir ve yenisi üretilir. Hash eşleştirmesi sabit zamanlı karşılaştırma kullanır.
- Refresh token isteğinin alanlarına uzunluk/doğrulama sınırları eklendi.
- Yeni anahtar devrinde eski public key'lerin `Jwt__PreviousSigningPublicKeys__N` alanlarıyla geçici olarak doğrulamaya eklenmesi desteklenir.

## Diğer yapılandırma alanları

`.env.example` ve `appsettings.json` içinde şu alanlar tanımlandı:

- Google OAuth/Web Client, Android package/SHA-1; Play Integrity ve Play Developer API servis hesabı alanları.
- PostgreSQL ana, salt-okunur ve migration bağlantı dizeleri; havuz, bağlantı ve komut zaman aşımı ayarları.
- Redis parolası, TLS, key prefix, oturum süresi, oda kilidi ve reconnect ayarları.
- RabbitMQ bağlantısı, kuyruk prefix'i ve retry sayısı.
- Oda kapasitesi, oyun tick hızı, reconnect ve matchmaking süreleri, guest temizliği, minimum istemci sürümü, bakım ve drain bayrakları.
- Rate limit eşikleri, Sentry/Seq/metrics, Data Protection anahtar konumu, FCM, e-posta, feature flag, Cloudflare ve iç servis anahtarı alanları.

Tick hızı, reconnect bekleme süresi ve genel/auth istek limitleri sunucu kodunda yapılandırmadan okunur. Guest/oda/mesaj limitleri ve üçüncü taraf servis alanları yapılandırma şablonunda tanımlıdır; ilgili servis entegrasyonları veya ayrı limit kuralları eklenene kadar aktif davranış olarak değerlendirilmemelidir.

## Doğrulama

- `.env` içindeki RSA anahtarının en az 3072 bit olduğu; pepper, PostgreSQL ve Redis parolalarının asgari rastgele uzunlukları karşıladığı kontrol edildi. Değerler terminale yazdırılmadı.
- PowerShell başlatma betiklerinin sözdizimi kontrol edildi.
- `dotnet build server\Fireman.Api\Fireman.Api.csproj --no-restore` başarılı tamamlandı: **0 hata**. Derleme mevcut kod tabanındaki analyzer uyarılarını raporladı.
- Flutter `dart format` işlemi bu ortamda yanıt vermedi ve durduruldu; Flutter analiz/derlemesi bu düzenlemeler için doğrulanmadı.
- Testler çalıştırılmadı.

## Dışarıdan sağlanması gereken değerler

Google OAuth Client ID/Secret, Android SHA-1, Firebase Project ID, Play Integrity/Developer API servis hesabı, FCM, e-posta ve gözlemleme sağlayıcı bilgileri ilgili Google/Firebase/servis panellerinden alınmalıdır. Örnek dosyada yer tutucu/boş bırakılmıştır; gerçek değerler `.env` veya üretim secret manager üzerinden sağlanmalıdır.

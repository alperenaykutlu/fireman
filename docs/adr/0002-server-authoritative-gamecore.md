# ADR-0002: Sunucu Otoriter 30Hz Deterministik Simülasyon Motoru (GameCore)

## Durum
Kabul Edildi

## Bağlam
İstemci tarafında çalışan simülasyon modeli hileye açık olup (hız, ışınlanma, sınırsız bomba) çok oyunculu maçlarda senkron kaymalarına neden olmaktaydı.

## Karar
- Tüm oyun mantığı sunucu tarafında saf C# (`net10.0`) ile yazılmış bağımsız `Fireman.GameCore` kütüphanesine taşınmıştır.
- Simülasyon render hızından bağımsız sabit 30 Hz zaman adımlı (`dt = 33.33ms`) deterministik bir döngüyle koşturulur.
- Float yuvarlama farklarını önlemek amacıyla $1\text{ hücre} = 256\text{ sub-unit}$ tamsayı (fixed-point) fiziği benimsenmiştir.
- Her tick sonrasında FNV-1a durum hash'i hesaplanarak istemci ve sunucu arasındaki senkronizasyon bit-bit doğrulanır.

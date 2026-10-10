# ADR-0003: Ağ İletişiminde SignalR MessagePack İkili Protokolü

## Durum
Kabul Edildi

## Bağlam
30 Hz frekansında gönderilen `PlayerInputDto` ve 20 Hz frekansında yayınlanan `WorldSnapshotDto` paketleri JSON formatında serileştirildiğinde mobil cihazlarda yüksek bant genişliği tüketimine (15-20 KB/s) ve JSON parse gecikmesine yol açmaktadır.

## Karar
- SignalR gerçek zamanlı iletişim katmanında `Microsoft.AspNetCore.SignalR.Protocols.MessagePack` ikili (binary) serileştirme protokolü zorunlu kılınmıştır.
- Bu geçiş ile payload boyutları %60–70 oranında düşürülmüş, oyuncu başına indirme trafiği < 8 KB/s, yükleme trafiği ise < 2 KB/s seviyesine indirilmiştir.

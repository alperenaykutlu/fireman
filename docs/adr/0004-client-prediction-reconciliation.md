# ADR-0004: İstemci Tarafı Tahmin (Prediction) ve Sunucu Uzlaştırması (Reconciliation)

## Durum
Kabul Edildi

## Bağlam
Sunucu otoriter mimaride oyuncu hareket komutları sunucuya gidip snapshot olarak dönene kadar (100–150 ms) yerel hareket gecikirse oyun "ağır ve hantal" hissedilir.

## Karar
- İstemci (Flutter) tarafında yalnızca yerel oyuncu hareketini anında uygulayan hafif bir `PredictionEngine` çalıştırılır.
- Her yerel girdiye artan bir `seq` atanır ve sunucudan onay gelene kadar bir tamponda (`_pendingInputs`) saklanır.
- Sunucudan `lastAckedSeq` içeren yetkili `WorldSnapshot` geldiğinde, istemci pozisyonu sunucunun söylediği noktaya çeker ve onay bekleyen girdileri tekrar üzerine uygular (reconciliation).
- **Sınırlandırma İlkesi:** İstemci tahmini yalnızca hareketle sınırlandırılmıştır; bomba bırakma, patlama, hasar ve güçlendirici toplama kararları **her zaman sunucudan gelir**. Böylece kural sapması ve hile yüzeyi engellenir.

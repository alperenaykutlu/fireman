# ADR-0006: Deterministik Izgara Doğrulama ve Davranışsal Anti-Cheat

## Durum
Kabul Edildi

## Bağlam
İstemci tarafı kod enjeksiyonu, hız hileleri (speed-hack), duvarlardan geçme (noclip) ve zamanlama manipülasyonu klasik online oyunların başlıca tehditleridir.

## Karar
1. **Mimari Otorite:** İstemci sunucuya yalnızca ham girdileri (`PlayerInputDto`: yön, bomba bırakma, dizi numarası) bildirir. İstemci koordinatları asla doğrudan kabul edilmez.
2. **Izgara Doğrulama (Grid Validation):** Sunucu çekirdeği (`Fireman.GameCore`), 256 alt birimli sabit nokta ızgara üzerinde çarpışma testlerini tek otorite olarak icra eder.
3. **Davranışsal Anomali Tespiti:**
   - İstemci tahmin hatası (prediction error) eşiğin üzerine çıkarsa veya sıra dışı tick atlamaları yaşanırsa `AntiCheatLog` tablosuna audit kaydı düşülür.
   - Saniyede izin verilen azami girdi frekansı (30Hz + %10 buffer) aşıldığında paketler düşürülür.

## Sonuçlar
- **Olumlu:** Hilelerin %99'u mimari olarak imkansız hale getirilir.
- **Olumsuz:** İstemcide yüksek ping dalgalanmalarında sunucu uzlaştırması (reconciliation) oyuncuyu geri çekebilir (snap-back).

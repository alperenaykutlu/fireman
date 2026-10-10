# ADR-0009: Flutter Feature-First Mimarisi ve Flame Ayrımı

## Durum
Kabul Edildi

## Bağlam
Flutter istemcisinin hem karmaşık UI (menüler, klanlar, envanter, mağaza, profil) hem de yüksek performanslı 60fps 2D oyun ızgarasını render etmesi gerekmektedir. Katman bazlı (layer-first) yapılar büyüdükçe kod tabanının bakımını zorlaştırır.

## Karar
1. **Feature-First Klasör Yapısı:** İstemci özellikleri `features/<feature_name>/{data, domain, presentation}` hiyerarşisi altında bağımsız modüller halinde organize edilir (`auth`, `lobby`, `gameplay`, `social`, `shop`).
2. **Durum Yönetimi:** Riverpod (`StateNotifierProvider` / `NotifierProvider`) ile reaktif, test edilebilir ve izole durum takibi yapılır.
3. **Flame Render Katmanı:**
   - Flutter Widget ağacı yalnızca UI kontrollerini,HUD'ı ve lobi ekranlarını barındırır.
   - Oyun haritası, bombalar, karakter sprite'ları ve alev efektleri Flame Engine canvas'ında 60fps optimize şekilde çizilir.
4. **Prediction Engine:** Oyun girdileri yerel olarak simüle edilir (`prediction_engine.dart`), sunucudan snapshot geldiğinde hata farkı düzeltilir (reconciliation).

## Sonuçlar
- **Olumlu:** UI ve oyun motoru temiz bir şekilde ayrılır, özellikler birbirinden izole geliştirilebilir.
- **Olumsuz:** İki ayrı durum ağacının (Flutter UI state ve Flame game loop) senkronizasyon disiplini gerektirmesi.

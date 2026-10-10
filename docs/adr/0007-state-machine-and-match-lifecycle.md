# ADR-0007: Sonlu Durum Makineleri (FSM) ve Maç Yaşam Döngüsü

## Durum
Kabul Edildi

## Bağlam
Maçların lobi aşamasından geri sayıma, aktif çatışmaya, ani ölüm (sudden death) aşamasına ve maç sonu ödül dağıtımına geçişi karmaşık yan etkilere ve yarış durumlarına (race conditions) gebedir.

## Karar
1. Maç durumu açık bir sonlu durum makinesi (Finite State Machine) ile yönetilir:
   - `LobbyWaiting` -> `Countdown` (3 sn) -> `Playing` -> `SuddenDeath` -> `Ended` -> `Disposed`.
2. Her durum geçişi atomik ve deterministiktir.
3. Maç sonlandığında (`Ended`):
   - Kazanan ve sıralamalar belirlenir.
   - Elo reytingleri `EloRatingCalculator` ile hesaplanır.
   - Ödül ledger kayıtları ve görev ilerlemeleri tek bir veritabanı transaction'ında kalıcı hale getirilir.
   - `MatchReplay` paketi oluşturulup arşivlenir.

## Sonuçlar
- **Olumlu:** Geçersiz durum geçişleri engellenir, maç sonu çifte ödül veya eksik puan yazılma açıkları önlenir.
- **Olumsuz:** Durumlar arası geçişler ek kod disiplini ve katı sözleşme doğrulaması gerektirir.

# ADR-0001: Tek Doğruluk Kaynağı Olarak EF Core Migrations

## Durum
Kabul Edildi

## Bağlam
Projede hem ham SQL script'i (`001_InitialCreate.sql`) hem de C# Entity konfigürasyonları bulunmaktaydı. Bu durum iki ayrı kaynak arasında sapma (schema drift) riski doğuruyordu.

## Karar
- Veritabanı şemasında **tek doğruluk kaynağı (Single Source of Truth) Entity Framework Core Model Konfigürasyonları ve Migrations** olacaktır.
- Ham SQL betikleri yalnızca dağıtım anında `dotnet ef migrations script --idempotent` komutu ile otomatik türetilen yapıtlar (artifacts) olarak üretilecek; elle SQL yazılmayacaktır.
- CI sürecinde temiz bir PostgreSQL Testcontainer üzerinde migration'lar çalıştırılarak schema drift testi zorunlu kılınacaktır.

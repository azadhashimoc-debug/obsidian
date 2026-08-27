# SMM Panel Mimari Denetimi (ARCHITECTURE_AUDIT)

## 1. Kod Kalitesi ve Mimarisi
- **Servis Katmanı**: Domain mantığı ve finansal API entegrasyonu başarıyla view'lardan kopartılıp `core/services/` (payments.py, orders.py vb.) modüllerine taşınmıştır.
- **İşlem Güvenilirliği**: Sıkışan ve hatalı cevap alan siparişler asenkron işlemler aracılığıyla (`submit_order_task`) yürütülmekte, geri ödemeleri `refund_canceled_order` tarafından otomatik yapılmaktadır.
- **Teknik Borç**: Kod kalitesi çok yüksektir, ancak sistem tasarımı başından beri rollere göre ayrılmamıştır.

## 2. Bulunan Mimari Hatalar
- İstenen `SUPPORT_AGENT`, `RESELLER` gibi rol kırılımlarının hiçbir mimari modeli veya veri yapısı yoktur. Sistemin bütün yetki denetimi `is_staff` / `is_superuser` gibi yekpare bir mimari üzerindedir.
- Celery zamanlanmış görevleri (cron) Redis üzerinden başarılı bir şekilde çalışmaktadır (`recover_stuck_orders`), ancak Rate Limit'in Redis yerine SQL'de (Database) tutulması, yatay ölçeklenebilirliği sınırlamaktadır.

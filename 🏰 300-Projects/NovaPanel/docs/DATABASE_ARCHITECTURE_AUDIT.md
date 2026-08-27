# SMM Panel Veritabanı ve Mimari Denetimi

## 1. Veritabanı Mimarisi (DATABASE_AUDIT)

- **Veri Tipleri**: Parasal değerler için float yerine `DecimalField(max_digits=12, decimal_places=4)` kullanımı yapılmıştır. Bu, floating-point hatalarını sıfıra indirmektedir ve finansal uygulamalar için en iyi pratiklerden biridir.
- **Constraints (Kısıtlamalar)**: `CheckConstraint` kullanılarak bakiyelerin sıfırın altına düşmesi veritabanı seviyesinde yasaklanmıştır (`balance__gte=0`). Bu, race condition olsa dahi bakiyenin eksiye düşmesini engeller. Mükemmel bir güvenlik katmanıdır.
- **İlişkiler ve İndeksler**: `user_created_idx`, `status_created_idx` gibi composite indeksler oluşturulmuştur. Bu durum `stuck_orders` ve admin panelindeki dashboard sorgularının hızlı çalışmasını sağlar.
- **Orphan Kayıtlar**: `on_delete=models.PROTECT` kullanılarak siparişlerin veya servislerin kazara silinmesinin, ilişkili cüzdan hareketlerini (WalletTransaction) bozması (orphan bırakması) engellenmiştir.
- **N+1 Sorgu Sorunları**: `views.py` dosyasında (örneğin `dashboard`, `order_history`) `select_related("service", "category")` kullanılarak N+1 problemi büyük ölçüde çözülmüştür.

### Bulunan Sorunlar:
- `WalletTransaction` tablosunda soft-delete bulunmamaktadır, ancak bu finansal mutabakat için istenen bir davranış olabilir (immutability). Sadece log niteliğinde olan `RateLimitCounter`'lar hızla şişebilir, 24 saatte bir silinmesi için cron job bulunmaktadır, ancak tablonun aşırı büyümesi production'da sorun yaratabilir.

## 2. Mimari İnceleme (ARCHITECTURE_AUDIT)

- **Domain İzolasyonu**: İş mantığı (Business Logic) view'lardan arındırılarak `core/services/` klasörü altına (orders.py, payments.py, wallets.py, vb.) taşınmıştır. Bu yaklaşım kodun test edilebilirliğini ve bakımını inanılmaz derecede kolaylaştırır (Fat Models / Skinny Views veya Service Layer pattern).
- **Provider API Entegrasyonu**: Asenkron Celery görevleri ile `submit_order_task`, `sync_order_statuses` fonksiyonları çağrılmaktadır.
  - Sıkışan siparişler (stuck orders), `recover_stuck_orders` ile kurtarılmakta ve timeout olanlar `refund_canceled_order` ile iade edilmektedir. Mimari, ağ kaynaklı (Transport) hatalara karşı son derece dayanıklıdır.
- **Eşzamanlılık Yönetimi**: Aynı siparişin iki kere gönderilmesini önlemek için:
  ```python
  claimed = Order.objects.filter(pk=order_id, status="queued", provider_order_id="").update(...)
  ```
  mantığı kullanılmış. Bu kilit beklemeden, atomik olarak işlem kapma (claiming) yöntemidir ve oldukça ölçeklenebilirdir.
- **Teknik Borç**: Rol sisteminin mock düzeyinde olması en büyük teknik borçtur. Sistem şu an admin panelini tek yetki (is_staff) ile çalıştırdığı için operasyonel personel (Support Agent) müşteri bakiyesine admin ile aynı seviyede müdahale edebilir.

## 3. Finansal Bütünlük
- Geri ödemeler (`_apply_refund` metodunda) yalnızca fark kadar ödenir. `target_total - order.refunded_amount` mantığı ile mükerrer refund işlemleri (duplicate refund) engellenmiştir.
- Admin bakiye ayarlamaları `adjust_balance` üzerinden yapılmakta ve her işlem için `WalletTransaction` kaydı oluşturulmaktadır. Loglanmayan hiçbir hareket yoktur.

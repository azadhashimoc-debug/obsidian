# SMM Panel Veritabanı Denetimi (DATABASE_AUDIT)

## 1. Veritabanı Mimarisi
- **Veri Tipleri**: Parasal değerler (bakiye, fiyat, tutar) için float yerine `DecimalField(max_digits=12, decimal_places=4)` kullanımı yapılmıştır. Floating-point hesaplama hataları sıfıra indirilmiştir.
- **Constraints (Kısıtlamalar)**: `CheckConstraint` kullanılarak cüzdan bakiyelerinin (Wallet.balance) sıfırın altına düşmesi (`balance__gte=0`) veritabanı seviyesinde yasaklanmıştır.
- **Foreign Key İlişkileri**: İşlemler, Siparişler ve Kullanıcılar arasında tam bütünlük (`on_delete=models.PROTECT`) kurularak veri kaybı ve orphan kayıt oluşması engellenmiştir.

## 2. Sorunlar ve Riskler
- **SQLite Fallback**: `config/settings.py` içinde PostgreSQL URL bulunmazsa sistemin SQLite'a düşmesine izin verilmiştir. SQLite, production düzeyinde çoklu yazma yaparken eşzamanlı kilitleri tam yönetemez. Bu durum race condition engellemek için kullanılan `select_for_update()` fonksiyonunun patlamasına sebep olur.
- **Rate Limit Tablosu**: `RateLimitCounter` tablosu sürekli kayıt alan yapıdadır. Sürekli SQL yazılması yoğun trafikte PostgreSQL sunucusunu yorabilir.

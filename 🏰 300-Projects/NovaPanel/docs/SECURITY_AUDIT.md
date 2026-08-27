# SMM Panel Güvenlik Denetimi (SECURITY_AUDIT)

## 1. Tespit Edilen Güvenlik Açıkları

### ID-1: Engellenen Kullanıcıların Sessionlarının Düşmemesi (Session Invalidation)
- **Seviye**: HIGH
- **Kategori**: Authentication / Session Management
- **Etkilenen Dosyalar**: `config/settings.py` (Eksik middleware)
- **Sorunun Açıklaması**: Django, sükunetle (default) `user.is_active = False` ataması yapıldığında mevcut `session_id` cookie'lerini sunucu tarafında invalidate etmez. Kullanıcı banlandığında, daha önceden login olmuş cihazlardan paneli kullanmaya, hatta bakiye/sipariş işlemlerine devam edebilir.
- **Gerçek Etkisi**: Yasaklanmış veya şüpheli kullanıcının hesabı askıya alınmasına rağmen sistemi manipüle etmesi.
- **Önerilen Çözüm**: Özel bir middleware yazılarak veya her request'te `request.user.is_active` kontrolü yapılarak aktif sessionlar engellenmeli ve logout işlemi zorlanmalıdır.

### ID-2: Rol ve Yetki İzolasyonunun Olmaması
- **Seviye**: CRITICAL
- **Kategori**: Authorization
- **Etkilenen Dosyalar**: `core/models.py`, `core/admin.py`
- **Sorunun Açıklaması**: İstenen rol katmanları (SUPPORT_AGENT, ADMIN, RESELLER vb.) sistemde bulunmamaktadır. Dolayısıyla `is_staff = True` yapılan bir destek temsilcisi, tüm finansal işlemlere ve site ayarlarına (SiteSetting) müdahale edebilme potansiyeline sahiptir.
- **Önerilen Çözüm**: Django Groups veya özel `Role` modeli kullanılarak Object-Level veya View-Level Permission sistemi kurulmalıdır. `has_change_permission` override edilerek hiyerarşi koda dökülmelidir.

### ID-3: SQLite ve Eşzamanlılık Riski
- **Seviye**: HIGH
- **Kategori**: Veri Bütünlüğü
- **Etkilenen Dosyalar**: `config/settings.py`
- **Sorunun Açıklaması**: Kod içerisinde `Wallet.objects.select_for_update()` sıkça kullanılmıştır, bu da eşzamanlı bakiye düşümlerinde (Race Condition) koruma sağlar. Ancak `settings.py` dosyasında `DATABASE_URL` tanımlanmazsa fallback olarak SQLite çalışmaktadır. SQLite, `select_for_update` semantiğini native olarak desteklemez ve tüm DB'yi yazma anında kilitler. Production ortamında bir DevOps hatası projeyi SQLite ile ayağa kaldırırsa, kilitlenmeler ve potansiyel veri kayıpları yaşanır.
- **Önerilen Çözüm**: Production için `DATABASES` konfigürasyonunda sadece PostgreSQL zorlanmalı, fallback kodu silinmelidir.

## 2. API ve Backend Güvenliği Kontrolü
- **Input Validation**: `forms.py` üzerinden yapılmaktadır. Turnstile CAPTCHA entegrasyonu başarılıdır. (Geçti)
- **Rate Limiting**: `RateLimitCounter` üzerinden sağlanmaktadır. SQL enjeksiyondan korunmuştur ancak performansı şüphelidir. (Geçti - Performans riski mevcut)
- **CSRF & XSS**: Django'nun built-in korumaları aktif edilmiştir. CSV injection zafiyetine karşı `csv_cell()` metodu yazılmıştır. (Geçti)
- **API Key Sızıntısı**: `os.getenv` üzerinden okunan anahtarlar koda hardcode edilmemiş, loglara yazılmamıştır. (Geçti)
- **IDOR**: `admin.py` içerisinde `adjust_balance` (Bakiye düzeltme) işlemi yaparken IDOR riski analiz edildi, ancak `self.has_change_permission(request, wallet)` ile korunuyor. Makbuz görüntüleme uç noktası `payment_receipt` de izole edilmiş ve korumalıdır. (Geçti)

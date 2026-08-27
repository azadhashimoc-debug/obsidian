# İyileştirme ve Uygulama Planı (REMEDIATION_PLAN)

## Aşama 0: Acil Güvenlik ve Veri Riskleri
**Hedef**: Mevcut güvenliği yayın aşamasına getirmek.
- [ ] Özel bir `SessionInvalidationMiddleware` yazılarak `request.user.is_active` kontrolü yapılacak. Kullanıcı pasife alındığında oturumlar zorla kapatılacak.
- [ ] `settings.py` içerisindeki `DATABASES` fallback kapatılıp, sunucuda PostgreSQL çalışmaması durumunda sistemin fail-fast (anında çökmesi) mekanizması sağlanacak. SQLite kullanımı engellenecek.

## Aşama 1: Production Blocker'lar (Rol Sistemi)
**Hedef**: Çok katmanlı personel yetkilendirmesi.
- [ ] Django'nun kendi Group sistemi veya özel bir `Role` modeli kullanılarak SUPER_ADMIN, ADMIN, SUPPORT_AGENT, OPERATIONS_AGENT, RESELLER rolleri oluşturulacak.
- [ ] `core/admin.py` içerisindeki tüm ModelAdmin sınıflarına `has_view_permission`, `has_change_permission`, `has_delete_permission` override'ları eklenerek personelin yetki seviyesine göre ekranlar gizlenecek.

## Aşama 2: Temel Sistem Doğruluğu ve Test Hataları
**Hedef**: Operasyonel stabilite.
- [ ] Windows ortamındaki deployment/test süreçlerinde `\u0259` (Azerbaycan ə harfi) ve diğer UTF-8 karakterlerin çökme yapmaması için encoding işlemleri standartlaştırılacak (`PYTHONIOENCODING=utf-8` çevre değişkeni zorunlu hale getirilecek).

## Aşama 3: Performans ve Ölçeklenebilirlik
**Hedef**: Yüksek trafik dayanıklılığı.
- [ ] `RateLimitCounter` modeli veritabanı yorduğu için, Redis konfigürasyonu tamamlanarak rate limiting işlemleri (Login, Order creation, vb.) Redis-based hale getirilecek.

## Aşama 4: UX ve Kullanıcı Arayüzü
**Hedef**: Müşteri memnuniyeti.
- [ ] `new_order` ekranında Javascript kullanılarak kullanıcının girdiği miktara göre anlık fiyat (live-pricing) gösterimi eklenecek.
- [ ] Drip-feed ekranlarındaki UI iyileştirilecek.

## Aşama 5: Production Hazırlığı
**Hedef**: Devops süreçleri.
- [ ] Celery worker'lar için deployment scriptleri tamamlanacak (systemd veya supervisord konfigürasyonları).
- [ ] Provider timeout süreleri için `circuit breaker` mantığı eklenebilir, bu şekilde uzun cevap veren providerlar tüm sistemi kitlemez.

---
title: NovaPanel - Qərarlar Jurnalı
created: 2026-08-27
updated: 2026-08-27
type: decisions
project: NovaPanel
---

# 💡 NovaPanel Qərarlar Jurnalı (ADR)

### ADR-001: Asinxron Sifarişlər üçün Celery + Redis Seçimi
- **Tarix**: 2026-08-27
- **Kontekst**: SMM API provayderlərinə sifariş göndərildikdə şəbəkə gecikmələri istifadəçi interfeysində donmalara səbəb olurdu.
- **Qərar**: Sifarişlərin qəbulu dərhal queued statusu ilə aparılır, provayderə göndərilmə isə Celery worker-ləri tərəfindən arxa planda idarə olunur.
- **Nəticə**: İcra sürəti artırıldı, HTTP timeout riski sıfıra endirildi.

### ADR-002: Təhlükəsizlik və Maliyyə İntizamı
- **Tarix**: 2026-08-27
- **Kontekst**: Qəbzlərin ictimai çıxışda qalması və balans uyğunsuzluqları maliyyə itkisinə səbəb ola bilərdi.
- **Qərar**: Qəbzlər MEDIA_ROOT-dan kənar private-media/ daxilində saxlanılır və yalnız səlahiyyətli istifadəçiyə servis olunur.
- **Nəticə**: Tam məxfilik və təhlükəsizlik təmin edildi.

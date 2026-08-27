---
title: NovaPanel - Tapşırıqlar və Status
created: 2026-08-27
updated: 2026-08-27
type: tasks
project: NovaPanel
status: active
---

# 📋 NovaPanel Tapşırıqlar Lövhəsi

## 🟢 Cari Status: Production Hazırlığı & Marketinq Başlanğıcı

### ⚡ Yüksək Prioritetli Açıq İşlər (P0)
- [ ] VPS serverdə son konfiqurasiya və deploy testi (python manage.py check --deploy)
- [ ] PostgreSQL və Redis bağlantılarının canlı mühitdə yoxlanılması
- [ ] Meta Ads reklam kreativlərinin (Story & Feed 1080x1920) canlı kampaniyaya buraxılması

### 🟡 Orta Prioritetli İşlər (P1)
- [ ] PanelBaku API inteqrasiyasında xidmətlərin sinxronlaşdırılması
- [ ] Takılmış sifarişlərin bərpası üçün cron/task-ın tənzimlənməsi (
ecover_stuck_orders)
- [ ] TikTok/Reels video çəkilişi və organik paylaşımların hazırlanması

### 🔵 Gələcək Təkmilləşdirmələr (P2)
- [ ] Əlavə ödəniş qapılarının (kartla birbaşa ödəniş) inteqrasiyası
- [ ] İstifadəçi loyallıq proqramı və referal sistemi

### ✅ Tamamlanmış İşlər (Done)
- [x] Django backend əsas modelləri və admin paneli
- [x] Celery & Redis asinxron sifariş idarəetməsi
- [x] Bank qəbzlərinin təhlükəsiz saxlanması (private-media/)
- [x] Rate limiting və anti-fraud qorunması

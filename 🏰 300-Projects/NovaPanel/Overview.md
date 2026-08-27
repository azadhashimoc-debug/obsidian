---
title: NovaPanel (Panelim.az) Layihe Merkezi
created: 2026-08-27
modified: 2026-08-27
type: project
status: active
tags: [project, django, smm, saas, panelim, marketing]
---

# 🚀 NovaPanel / Panelim.az

Azərbaycan bazarı üçün hazırlanmış dinamik, yüksək təhlükəsizlikli və avtomatlaşdırılmış SMM panel və xidmət platforması.

---

## 📌 Əsas Texniki Məlumatlar
- **Backend**: Django (Python 3.12+), Celery + Redis (Asinxron sifarişlər və zamanlanmış işlər)
- **Verilənlər Bazası**: PostgreSQL (İstehsalat), SQLite (Lokal test)
- **Təhlükəsizlik & Şəbəkə**: Cloudflare Turnstile, Nginx, CSP (Content Security Policy), Rate Limiting, Maliyyə Mutabiqəti (Reconciliation Ledger)
- **Ödəniş & Əməliyyatlar**: Bank qəbzlərinin saxlanması (private-media/), avtomatik vaxtı bitmiş sessiyaların ləğvi, takılmış sifarişlərin bərpası.

---

## 🧭 Layihə Bələdçisi & Daxili Sənədlər

### 1. Texniki Arxitektura & Yayım
- 📖 [[🏰 300-Projects/NovaPanel/README.md|Əsas README & Quraşdırma]]
- 🏗️ [[🏰 300-Projects/NovaPanel/docs/ARCHITECTURE_AUDIT.md|Sistem Arxitektura Auditi]]
- 🗄️ [[🏰 300-Projects/NovaPanel/docs/DATABASE_ARCHITECTURE_AUDIT.md|Verilənlər Bazası & Ledger Quruluşu]]
- 🚀 [[🏰 300-Projects/NovaPanel/docs/PRODUCTION_READINESS.md|Production Hazırlıq Planı]]
- 🗺️ [[🏰 300-Projects/NovaPanel/yol-haritasi.md|İnkişaf Yol Xəritəsi (Roadmap)]]

### 2. Təhlükəsizlik, Audit & İmtahanlar
- 🛡️ [[🏰 300-Projects/NovaPanel/saldiri-ve-suistimal-denetimi.md|Hücum və Sui-istifadə Qorunması]]
- 🔒 [[🏰 300-Projects/NovaPanel/docs/SECURITY_AUDIT.md|Təhlükəsizlik Auditi]]
- 🔍 [[🏰 300-Projects/NovaPanel/seo-denetimi.md|SEO və Axtarış Optimizasiyası]]
- 📋 [[🏰 300-Projects/NovaPanel/denetim-raporu.md|Ümumi Audit Hesabatı]]

### 3. Marketinq, Reklam & Satış Strategiyası
- 🎯 [[🏰 300-Projects/NovaPanel/marketing/panelim_winning_ad_campaign_plan.md|Qalib Meta Ads Kampaniyası Planı]]
- ✍️ [[🏰 300-Projects/NovaPanel/marketing/reklam-ve-sayfa-metinleri.md|Reklam & Landing Səhifə Mətnləri]]
- 🎬 [[🏰 300-Projects/NovaPanel/marketing/panelim_tiktok_script.md|TikTok & Reels Video Ssenariləri]]
- 🕵️ [[🏰 300-Projects/NovaPanel/marketing/competitor_ads.json|Rəqib Reklam Təhlili (Ad Spy)]]

---

## ⚡ Cari Status & Növbəti Addımlar
- [x] Django arxitekturası və baza modelləri tamamlandı
- [x] Celery & Redis asinxron sifariş idarəetməsi quruldu
- [x] Təhlükəsizlik və maliyyə mutabiqəti mexanizmi quruldu
- [ ] Meta Ads reklam kreativlərinin və büdcəsinin canlıya buraxılması
- [ ] Production VPS-də yekun deploy yoxlaması (check --deploy)

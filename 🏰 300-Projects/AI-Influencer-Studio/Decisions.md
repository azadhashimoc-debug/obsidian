---
title: AI Influencer Studio — Qərarlar Arxivi (ADR)
created: 2026-08-27
updated: 2026-08-27
type: decisions
project: AI-Influencer-Studio
---

# 🧠 AI Influencer Studio: Texniki və Biznes Qərarları

---

### ADR-001: Hədəf Bazar və Dil Seçimi
- **Tarix**: 2026-08-27
- **Qərar**: Layihə ilk mərhələdə birbaşa **Azərbaycan bazarına (Instagram Reels və TikTok)** və Azərbaycan dilinə fokuslanacaq.
- **Səbəb**: Azərbaycan bazarında AI influencer rəqabəti çox aşağıdır, yerli auditoriyanın marağı və viral yayılma potensialı qlobal bazara nisbətən daha sürətlidir. Yerli brendlərlə əlaqə qurmaq daha asandır.
- **Status**: `Qəbul edildi`

---

### ADR-002: Texnoloji Yanaşma (LivePortrait + ElevenLabs + OpenMontage)
- **Tarix**: 2026-08-27
- **Qərar**: Bahalı və nəzarətsiz 3D mühərriklər əvəzinə, fotorealist 2D sima (Flux.1) + Dəqiq Dodaq Sinxronu (`LivePortrait`) + Təbii Nitq (`ElevenLabs`) + Python əsaslı avtomatik montaj (`OpenMontage`) kombinasiyası seçildi.
- **Səbəb**: Bu kombinasiya ən yüksək fotorealizm, ən aşağı xərc və gündəlik avtomatlaşdırılmış video çıxarma sürəti təmin edir.
- **Status**: `Qəbul edildi`
- **Əlavə (2026-08-29)**: OpenMontage konkret repodur — https://github.com/calesthio/OpenMontage — `pip` paketi deyil. Quraşdırıldı və doğrulandı; montajı FFmpeg + Remotion ilə çıxarır. Bax: [[🛠️ 600-Arsenal/OpenMontage.md|Arsenal qeydi]].

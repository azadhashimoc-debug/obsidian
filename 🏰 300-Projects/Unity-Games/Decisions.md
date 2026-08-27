---
title: Unity Oyunları - Qərarlar Jurnalı
created: 2026-08-27
updated: 2026-08-27
type: decisions
project: Unity-Games
---

# 💡 Unity Oyunları Qərarlar Jurnalı (ADR)

### ADR-001: URP (Universal Render Pipeline) İstifadəsi
- **Kontekst**: Android cihazlarında yüksək FPS və vizual keyfiyyət balansı tələb olunur.
- **Qərar**: Bütün layihələr URP ilə hazırlanır, post-processing yalnız vacib zonalarda aktivləşdirilir.
- **Nəticə**: Geniş çeşidli mobil cihazlarda stabil 60 FPS təmin edilir.

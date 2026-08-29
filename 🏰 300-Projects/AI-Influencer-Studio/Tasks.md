---
title: AI Influencer Studio — Tapşırıqlar & Görüləcək İşlər
created: 2026-08-27
updated: 2026-08-29
type: tasks
project: AI-Influencer-Studio
---

# 📋 AI Influencer Studio: Görüləcək İşlər

---

## 🚀 Faza 1: Personaj Konsepti & Vizual Dizayn (Prioritet: P0)
- [ ] **Modelin Şəxsiyyət Kartını Təyin Etmək**: Ad, yaş, xarakter, maraq sahələri (məs: dəb, texnologiya, Bakı həyatı).
- [ ] **Əsas Simanın (Face Model) Generasiyası**: Flux.1 / Stable Diffusion ilə 5-10 yüksək keyfiyyətli master portret yaratmaq.
- [ ] **Vizual Konsistentlik Qaydaları**: Eyni üzü müxtəlif geyimlərdə və məkanlarda sabit saxlamaq üçün prompt və LoRA/FaceID şablonunu hazırlamaq.

---

## 🎙️ Faza 2: Səs & Canlandırma Pipeline-ı (Prioritet: P0)
- [ ] **Azərbaycan Dilli Səs Seçimi / Klonlanması**: ElevenLabs üzərində təbii, cəlbedici qadın səsi təyin etmək.
- [ ] **LivePortrait / Hedra Dodaq Sinxronu**: Master portreti səs faylı ilə sinxronlaşdırıb real mimikalı video çıxarmaq.
- [ ] **Test Videosu**: 15-30 saniyəlik ilk danışıq videosunu generasiya edib keyfiyyəti yoxlamaq.

---

## 🎬 Faza 3: Avtomatlaşdırılmış Montaj (OpenMontage) (Prioritet: P1)
- [x] **OpenMontage Quraşdırılması** (2026-08-29): Repo klonlandı, `make setup` uğurla keçdi, ffmpeg əlavə edildi. 37 açarsız alət hazır, demo render uçdan-uca doğrulandı (1080p30 h264). Detallar: [[🛠️ 600-Arsenal/OpenMontage.md|OpenMontage]].
- [ ] **CapCut Tərzi Altyazı Axını**: `remotion_caption_burn` + `subtitle_gen` alətlərini Azərbaycan dilli sözbəsöz yanan altyazı üçün konfiqurasiya etmək.
- [ ] **API Açarlarının Doldurulması**: `.env` içinə `ELEVENLABS_API_KEY` və şəkil generasiyası üçün bir provider açarı (`tts` 1/10, `image_generation` 0/16 vəziyyətindədir).
- [ ] **Şablon Hazırlığı**: 9:16 vertikal format, cəlbedici şriftlər və arxa fon musiqi inteqrasiyası.

---

## 📱 Faza 4: Sosial Media & Paylaşım (Prioritet: P1)
- [ ] **Instagram & TikTok Hesablarının Qurulması**: Bioqrafiya, profil fotosu və hekayə başlıqlarının dizaynı.
- [ ] **İlk 10 Video Paketi**: İlk 10 viral mövzulu Reels skriptini yazıb videolarını istehsal etmək.
- [ ] **Gündəlik Paylaşım Qrafiki**: Hər gün ən aktiv saatlarda (18:00–21:00) paylaşım rejimi.

---

## 💰 Faza 5: Monetizasiya & Tərəfdaşlıq (Prioritet: P2)
- [ ] **Media Kit & Qiymət Cədvəli**: 10k izləyicidən sonra yerli brendlər üçün reklam qiymətlərini müəyyən etmək.
- [ ] **Affiliate Məhsul Linkləri**: Trendyol/yerli mağazalar üçün bioqrafiya linklərini aktivləşdirmək.

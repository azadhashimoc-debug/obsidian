---
title: OpenMontage — AI Video Pipeline Alət Zənciri
created: 2026-08-29
modified: 2026-08-29
type: tool
status: active
tags: [openmontage, video, montaj, remotion, ffmpeg, ai-influencer-studio]
---

# 🎬 OpenMontage

**Repo:** https://github.com/calesthio/OpenMontage
**Nə edir:** Skript → səs → səhnə → montaj zəncirini idarə edən Python orkestratoru.
Montajı özü FFmpeg + **Remotion** (React/TSX kompozisiya) ilə çıxarır; 25 kateqoriyada
117 provider (TTS, şəkil, video, musiqi, analiz) qeydiyyatdan keçir.
**Lisenziya:** repo daxilində `LICENSE` (48 KB — istifadədən əvvəl oxu).

> [!warning] Vacib
> Bu `pip install openmontage` deyil. PyPI paketi yoxdur — repo klonlanır və
> içindəki `.venv` ilə işlədilir. `make setup` standart quraşdırma yoludur.

---

## ✅ Doğrulanmış Quraşdırma (2026-08-29, Linux/Ubuntu 24.04)

```bash
git clone https://github.com/calesthio/OpenMontage.git
cd OpenMontage
make setup          # .venv yaradır, requirements.txt, npm install, piper-tts, .env
sudo apt install -y ffmpeg
make preflight      # hansı alətlərin hazır olduğunu göstərir
```

**Ön şərtlər:** Python ≥ 3.10 · Node.js ≥ 22 · npm · FFmpeg · (istəyə bağlı) `uv`

`make setup` bunları edir: `.venv` qurur → `requirements.txt` (pyyaml, pydantic,
Pillow, numpy, google-genai, openai, fastapi…) → `remotion-composer/` üçün
`npm install` (201 paket) → `piper-tts` (pulsuz offline TTS) → HyperFrames npx
keşini isindirir → `.env.example`-dan `.env` yaradır.

---

## 📊 Quraşdırmadan sonrakı vəziyyət

| | Say |
| --- | --- |
| **Açarsız işləyən alət** (lokal) | **37** |
| API açarı gözləyən | 81 |

**Açarsız hazır olanlar:** bütün `video_post` (9 — `video_compose`, `video_stitch`,
`auto_reframe`, `silence_cutter`, `green_screen`, `hyperframes_compose`),
`subtitle` (2 — `subtitle_gen`, `remotion_caption_burn` ← **CapCut tərzi altyazı buradadır**),
`character_animation` (6), `analysis` (7), `audio_processing` (2), `piper_tts`,
`pixabay_music`, `export_bundle`, ekran yazısı və Three.js dünya alətləri.

**Boş qalan kritik kateqoriyalar:** `tts` (10-dan yalnız piper), `image_generation` (0/16),
`video_generation` (0/26), `avatar` (0/4) — hamısı `.env` içində açar istəyir.

**Layihə üçün lazım olan açarlar** (`.env`):
`ELEVENLABS_API_KEY` (səs, ADR-002) · şəkil üçün Flux/OpenAI/Google açarlarından biri.

---

## ⚠️ Tələlər (canlı sınaqda tapıldı)

1. **`piper` yalnız venv aktivləşəndə görünür.** Registry `cmd:piper`-i PATH-də axtarır;
   binar `.venv/bin/piper` içindədir. `source .venv/bin/activate` etməsən `tts` boş görünür.
2. **Remotion ilk render-də Chrome Headless Shell yükləyir** (`remotion.media`).
   Şəbəkə bağlıdırsa: `--browser-executable=/yol/headless_shell`.
3. **Proxy arxasında Google Fonts sertifikat xətası verir** → render `NetworkError` ilə düşür.
   Həlli: `--ignore-certificate-errors`.
4. **ffmpeg `make setup` daxilində gəlmir** — ayrıca quraşdır, yoxsa `hyperframes_compose`
   və bütün montaj alətləri `runtime_available=False` qalır.

---

## 🧪 Doğrulama testi

```bash
make demo-list      # code-to-screen · focusflow-pitch · world-in-numbers
cd remotion-composer && npx remotion render src/index.tsx Explainer out.mp4 \
  --props public/demo-props/focusflow-pitch.json --codec h264
```

**Nəticə (2026-08-29):** `focusflow-pitch` uğurla render olundu —
675 kadr, 22.5 san, 1920×1080 @ 30fps, h264 + aac, 4.2 MB. Zəncir uçdan-uca işləyir.

---

## 🔗 Əlaqəli

- [[🏰 300-Projects/AI-Influencer-Studio/Project.md|AI Influencer Studio]] — Faza 3 montaj mərhələsi
- [[🏰 300-Projects/AI-Influencer-Studio/Decisions.md|ADR-002]] — texnoloji yanaşma qərarı
- Sənədlər: repo daxilində `README.md` (44 KB), `AGENT_GUIDE.md` (48 KB), `PROMPT_GALLERY.md`

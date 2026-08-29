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

## 🎦 Backlot — canlı storyboard lövhəsi

FastAPI + uvicorn serveri, `projects/` qovluğunu izləyir və hər istehsalatın
mərhələlərini, ssenarisini, səhnə kartlarını, alət hadisələrini və xərcini canlı göstərir.
Lövhə heç nə hesabat vermir — hamısını diskdəki fayllardan törədir.

```bash
python -m backlot open              # kitabxana (serveri qaldırır + brauzeri açır)
python -m backlot open <project-id> # bir istehsalatın canlı lövhəsi
python -m backlot serve --port 4750 # yalnız server, ön planda
```

Default port **4750** (`BACKLOT_PORT` ilə dəyişir). `cmd_serve` host-u
**`127.0.0.1`-ə sabitləyir** — şəbəkədə görünməsi üçün uvicorn-u birbaşa çağır:
`python -m uvicorn backlot.server:app --host 0.0.0.0 --port 4750`.

### Tələ 5: demo simulyatoru sınıqdır
`scripts/backlot_simulate_run.py` `research`-dən birbaşa `script`-ə keçir, amma
`lib/checkpoint.py` artıq `proposal`-ı məcburi ön şərt sayır →
`CheckpointValidationError: PREREQUISITE VIOLATION`. Araya `proposal` mərhələsi
(`sample_artifact("proposal_packet")`) əlavə etdikdə tam işləyir.
Həmçinin skript `pytest` istəyir: əvvəlcə `pip install -r requirements-dev.txt`.

### Lövhəni serversiz paylaşmaq
Backlot UI-nin bütün server təması cəmi bir neçə nöqtədədir: `/api/project/<id>/state`
(yeganə data çağırışı), `/api/.../events` (SSE) və `/media` · `/thumb` (şəkillər).
board.js onsuz da **`?static=1`** parametrini tanıyır və canlı axını söndürür.
Ona görə lövhəni tək HTML fayla yığmaq mümkündür:

1. `load_board_state()` ilə state JSON-u çıxar (server qaldırmağa ehtiyac yoxdur),
2. `board.css` + `lib.js` + `board.js`-i inline et (`export`/`import` sətirlərini təmizlə),
3. `mediaURL`/`thumbURL`-i data-URI xəritəsinə yönləndir, `fetch`-i state ilə cavab verən shim-lə əvəz et,
4. `projectId`-ni sabitlə (normalda `location.pathname`-dan gəlir).

Nəticə: tıklanabilir, replay-i işləyən, internet tələb etməyən tək fayl.
Sənədləşdirmə və paylaşım üçün faydalıdır.

### VPS-də canlı yayımlamaq

`scripts/backlot-vps-deploy.sh` — Ubuntu/Debian VPS-də root olaraq işlədilir:

```bash
DOMAIN=backlot.panelim.az bash backlot-vps-deploy.sh   # domen + TLS
bash backlot-vps-deploy.sh                             # sadəcə IP, TLS-siz
```

Qurur: `/opt/openmontage` + venv → `backlot.service` (systemd, 127.0.0.1-də) →
nginx reverse proxy (basic auth) → certbot ilə HTTPS. Parolu bir dəfə çap edir.

> [!danger] Backlot-un autentifikasiyası YOXDUR
> Lövhə bütün istehsalat fayllarını, ssenariləri və xərcləri göstərir.
> Portu birbaşa internetə açmaq hamısını açıq qoymaq deməkdir.
> Skript ona görə nginx səviyyəsində parol qoyur — bunu çıxarma.

**Kritik detal — SSE nginx arxasında.** Lövhənin canlı qalması bu dörd sətirdən asılıdır:

```nginx
proxy_http_version 1.1;
proxy_set_header Connection "";
proxy_buffering off;          # açıq qalsa nginx axını tutur, lövhə donur
chunked_transfer_encoding off;
proxy_read_timeout 1h;        # qısa olsa axın hər dəfə qırılır
```

**Doğrulandı (2026-08-29)** — nginx + basic auth arxasında, real brauzerdə:
parolsuz 401, parolla 200; `events.jsonl`-a sətir yazıldıqda SSE `change` hadisəsi
saniyələr içində gəldi və lövhə **səhifə yenilənmədən** özünü yenilədi.

### Windows-da lokal

`scripts/Backlot-Qur.ps1` — sağ klik → "Run with PowerShell". Ön şərtləri yoxlayır,
repo klonlayır, venv + npm qurur, ffmpeg-i winget ilə çəkir, simulyator bug-ını
düzəldir, nümunə istehsalat yaradır və brauzeri açır.
Sintaksisi yoxlanılıb; simulyator düzəlişi real fayl üzərində sınaqdan keçirilib.
Windows-a xas addımlar (winget, `py -3.x`) sınanmayıb — orada ilk işlədən sənsən.

> [!note] Xaricdən giriş
> Uzaq konteynerdə lövhəni ictimai şəbəkəyə açmaq mümkün olmadı: inbound marşrut yoxdur
> və bütün tunel xidmətləri (trycloudflare, ngrok, localtunnel) egress siyasəti ilə bağlıdır.
> Öz maşınında bu problem yoxdur.

---

## 🔗 Əlaqəli

- [[🏰 300-Projects/AI-Influencer-Studio/Project.md|AI Influencer Studio]] — Faza 3 montaj mərhələsi
- [[🏰 300-Projects/AI-Influencer-Studio/Decisions.md|ADR-002]] — texnoloji yanaşma qərarı
- Sənədlər: repo daxilində `README.md` (44 KB), `AGENT_GUIDE.md` (48 KB), `PROMPT_GALLERY.md`

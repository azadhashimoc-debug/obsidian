<#
    Backlot-Qur.ps1 — OpenMontage-i qurur, nümunə istehsalat yaradır və
    canlı Backlot lövhəsini brauzerdə açır.

    İstifadə: fayla sağ klik -> "Run with PowerShell".
    Blok olunarsa PowerShell-də bir dəfə:
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

    Skript idempotentdir: təkrar işlədilə bilər, mövcud quraşdırmanı korlamır.
#>

$ErrorActionPreference = "Stop"

$Root    = if ($env:OPENMONTAGE_DIR) { $env:OPENMONTAGE_DIR } else { Join-Path $HOME "OpenMontage" }
$RepoUrl = "https://github.com/calesthio/OpenMontage.git"
$Port    = if ($env:BACKLOT_PORT) { [int]$env:BACKLOT_PORT } else { 4750 }
$Demo    = "ademos-demo"

function Say  ($m) { Write-Host "==> $m" -ForegroundColor Cyan }
function Ok   ($m) { Write-Host "    $m" -ForegroundColor Green }
function Warn ($m) { Write-Host "    $m" -ForegroundColor Yellow }
function Have ($c) { [bool](Get-Command $c -ErrorAction SilentlyContinue) }

# ---------------------------------------------------------------- ön şərtlər
Say "Ön şərtlər yoxlanılır"

$python = $null
foreach ($cand in @("py -3.12", "py -3.11", "py -3.10", "python")) {
    $exe, $arg = $cand -split " ", 2
    if (-not (Have $exe)) { continue }
    try {
        $v = if ($arg) { & $exe $arg -c "import sys; print('%d.%d' % sys.version_info[:2])" }
             else       { & $exe      -c "import sys; print('%d.%d' % sys.version_info[:2])" }
    } catch { continue }
    if ($v -and [version]$v -ge [version]"3.10") { $python = $cand; Ok "Python $v ($cand)"; break }
}
if (-not $python) { throw "Python 3.10+ tapılmadı. https://www.python.org/downloads/ -> quraşdırarkən 'Add to PATH' seç." }

if (-not (Have "node")) { throw "Node.js tapılmadı. https://nodejs.org/ -> LTS (>= 22) quraşdır." }
$nodeMajor = [int]((node --version) -replace "^v(\d+)\..*", '$1')
if ($nodeMajor -lt 22) { throw "Node.js $nodeMajor tapıldı, >= 22 lazımdır. https://nodejs.org/" }
Ok "Node $(node --version)"

if (-not (Have "git")) { throw "git tapılmadı. https://git-scm.com/download/win" }
Ok "git hazır"

if (-not (Have "ffmpeg")) {
    Warn "ffmpeg yoxdur — winget ilə quraşdırılır (montaj üçün məcburidir)"
    if (Have "winget") {
        winget install --id Gyan.FFmpeg -e --accept-source-agreements --accept-package-agreements
        $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                    [Environment]::GetEnvironmentVariable("Path", "User")
    }
    if (-not (Have "ffmpeg")) {
        Warn "ffmpeg hələ də PATH-də deyil. Quraşdırdıqdan sonra PowerShell-i yenidən aç."
        Warn "Onsuz lövhə işləyir, amma render alətləri 'unavailable' görünəcək."
    } else { Ok "ffmpeg quraşdırıldı" }
} else { Ok "ffmpeg hazır" }

# -------------------------------------------------------------------- klon
if (Test-Path (Join-Path $Root ".git")) {
    Say "Repo mövcuddur, yenilənir: $Root"
    git -C $Root pull --ff-only
} else {
    Say "Repo klonlanır: $Root"
    git clone $RepoUrl $Root
}
Set-Location $Root

# ------------------------------------------------------------------- venv
$VenvPy = Join-Path $Root ".venv\Scripts\python.exe"
if (-not (Test-Path $VenvPy)) {
    Say "Virtual mühit yaradılır (.venv)"
    $exe, $arg = $python -split " ", 2
    if ($arg) { & $exe $arg -m venv .venv } else { & $exe -m venv .venv }
} else { Ok ".venv mövcuddur" }

Say "Python asılılıqları quraşdırılır"
& $VenvPy -m pip install --upgrade pip --quiet
& $VenvPy -m pip install -r requirements.txt
& $VenvPy -m pip install -r requirements-dev.txt   # simulyator pytest istəyir
& $VenvPy -m pip install piper-tts                 # pulsuz offline TTS
if ($LASTEXITCODE -ne 0) { Warn "piper-tts quraşdırılmadı — TTS bulud provayderlərinə düşəcək"; $global:LASTEXITCODE = 0 }

Say "Remotion kompozitoru quraşdırılır (npm)"
Push-Location (Join-Path $Root "remotion-composer")
npm install
if ($LASTEXITCODE -ne 0) { Warn "npm install düşdü, 'npx --yes npm install' sınanır"; npx --yes npm install }
Pop-Location

if (-not (Test-Path (Join-Path $Root ".env"))) {
    Copy-Item .env.example .env
    Ok ".env yaradıldı — API açarlarını ora yaz (ELEVENLABS_API_KEY, FAL_KEY...)"
} else { Ok ".env mövcuddur" }

# ------------------------------------------- simulyator düzəlişi (upstream bug)
# scripts/backlot_simulate_run.py 'research'-dən birbaşa 'script'-ə keçir, amma
# lib/checkpoint.py 'proposal'-ı məcburi ön şərt sayır -> PREREQUISITE VIOLATION.
$Sim = Join-Path $Root "scripts\backlot_simulate_run.py"
$SimSrc = Get-Content $Sim -Raw
if ($SimSrc -notmatch 'cp\("proposal"') {
    Say "Demo simulyatorundakı əskik 'proposal' mərhələsi əlavə edilir"
    $rx  = [regex]'(?m)^([ \t]*)# script gates: awaiting_human -> approved'
    $add = @'
$1# proposal (məcburi ön şərt)
$1cp("proposal", "in_progress", {})
$1proposal = sample_artifact("proposal_packet")
$1save_artifact("proposal_packet", proposal)
$1cp("proposal", "completed", {"proposal_packet": proposal}, human_approved=True)

$1# script gates: awaiting_human -> approved
'@
    if ($rx.IsMatch($SimSrc)) {
        Set-Content $Sim ($rx.Replace($SimSrc, $add.TrimEnd("`r","`n"), 1)) -NoNewline
        Ok "simulyator düzəldildi"
    } else {
        Warn "gözlənilən sətir tapılmadı — upstream dəyişib, demo atlanacaq"
    }
}

# --------------------------------------------------- nümunə istehsalat + lövhə
if (-not (Test-Path (Join-Path $Root "projects\$Demo"))) {
    Say "Nümunə istehsalat yaradılır ($Demo)"
    & $VenvPy scripts/backlot_simulate_run.py --project $Demo --fast
    if ($LASTEXITCODE -ne 0) { Warn "demo yaradıla bilmədi — lövhə boş kitabxana ilə açılacaq"; $global:LASTEXITCODE = 0 }
} else { Ok "nümunə istehsalat mövcuddur" }

Say "Backlot serveri qaldırılır — http://127.0.0.1:$Port"
$env:BACKLOT_PORT = "$Port"

# Server ön planda işləyir (Ctrl+C ilə dayanır); brauzer ayrıca açılır.
$url = "http://127.0.0.1:$Port/p/$Demo"
Start-Job -ScriptBlock {
    param($u)
    for ($i = 0; $i -lt 40; $i++) {
        try { Invoke-WebRequest "$($u -replace '/p/.*$', '')/api/health" -UseBasicParsing -TimeoutSec 2 | Out-Null; break }
        catch { Start-Sleep -Milliseconds 500 }
    }
    Start-Process $u
} -ArgumentList $url | Out-Null

Write-Host ""
Ok "Lövhə: $url"
Write-Host "    Kitabxana:   http://127.0.0.1:$Port/" -ForegroundColor DarkGray
Write-Host "    Dayandırmaq: Ctrl+C (bu pəncərəni bağlama)" -ForegroundColor DarkGray
Write-Host ""

& $VenvPy -m backlot serve --port $Port

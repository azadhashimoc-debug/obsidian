#!/usr/bin/env bash
# backlot-vps-deploy.sh — Backlot-u VPS-də canlı, brauzerdən açılan servis kimi qurur.
#
#   Ubuntu/Debian VPS-də root olaraq:
#       DOMAIN=backlot.panelim.az bash backlot-vps-deploy.sh
#   Domen yoxdursa (birbaşa IP ilə, TLS-siz):
#       bash backlot-vps-deploy.sh
#
# Nə edir: OpenMontage-i /opt/openmontage-a qurur, Backlot-u systemd servisi kimi
# 127.0.0.1-də işə salır, nginx-i qarşısına parol qoruması ilə reverse proxy edir
# və DOMAIN verilibsə Let's Encrypt sertifikatı alır.
#
# Skript idempotentdir: təkrar işlədilə bilər.

set -euo pipefail

PORT="${PORT:-4750}"
DOMAIN="${DOMAIN:-}"
APP_DIR="${APP_DIR:-/opt/openmontage}"
SERVICE_USER="${SERVICE_USER:-backlot}"
AUTH_USER="${AUTH_USER:-adem}"
REPO="https://github.com/calesthio/OpenMontage.git"

say()  { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
ok()   { printf '    \033[32m%s\033[0m\n' "$*"; }
warn() { printf '    \033[33m%s\033[0m\n' "$*"; }
die()  { printf '\n\033[31mXƏTA: %s\033[0m\n' "$*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || die "root olaraq işlət (sudo)."

# ------------------------------------------------------------------ paketlər
say "Sistem paketləri"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq git curl ffmpeg nginx apache2-utils python3-venv python3-pip openssl
ok "git · ffmpeg · nginx · python3-venv hazırdır"

if ! command -v node >/dev/null 2>&1 || [ "$(node --version | sed 's/^v\([0-9]*\).*/\1/')" -lt 22 ]; then
    say "Node.js 22 quraşdırılır"
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
    apt-get install -y -qq nodejs
fi
ok "Node $(node --version)"

# --------------------------------------------------------------- servis useri
if ! id -u "$SERVICE_USER" >/dev/null 2>&1; then
    say "Servis istifadəçisi yaradılır: $SERVICE_USER"
    useradd --system --create-home --shell /usr/sbin/nologin "$SERVICE_USER"
fi

# ---------------------------------------------------------------------- repo
say "OpenMontage yerləşdirilir: $APP_DIR"
if [ -d "$APP_DIR/.git" ]; then
    git -C "$APP_DIR" pull --ff-only
else
    git clone --depth 1 "$REPO" "$APP_DIR"
fi

say "Python asılılıqları"
[ -x "$APP_DIR/.venv/bin/python" ] || python3 -m venv "$APP_DIR/.venv"
"$APP_DIR/.venv/bin/pip" install --quiet --upgrade pip
"$APP_DIR/.venv/bin/pip" install --quiet -r "$APP_DIR/requirements.txt"
"$APP_DIR/.venv/bin/pip" install --quiet -r "$APP_DIR/requirements-dev.txt"
ok "venv hazırdır"

[ -f "$APP_DIR/.env" ] || cp "$APP_DIR/.env.example" "$APP_DIR/.env"
mkdir -p "$APP_DIR/projects"
chown -R "$SERVICE_USER:$SERVICE_USER" "$APP_DIR"
chmod 600 "$APP_DIR/.env"

# ------------------------------------------------------------------- systemd
say "systemd servisi: backlot.service"
cat > /etc/systemd/system/backlot.service <<UNIT
[Unit]
Description=Backlot — OpenMontage canlı storyboard lövhəsi
After=network.target

[Service]
Type=simple
User=$SERVICE_USER
WorkingDirectory=$APP_DIR
Environment=BACKLOT_PORT=$PORT
ExecStart=$APP_DIR/.venv/bin/python -m uvicorn backlot.server:app --host 127.0.0.1 --port $PORT
Restart=always
RestartSec=3

# Lövhə yalnız oxuyur — yazma səlahiyyətini layihə qovluğu ilə məhdudlaşdır.
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$APP_DIR/projects

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable --now backlot.service
sleep 2
systemctl is-active --quiet backlot.service || {
    journalctl -u backlot.service -n 30 --no-pager
    die "backlot.service qalxmadı — yuxarıdakı loga bax."
}
ok "servis işləyir (127.0.0.1:$PORT)"

# ---------------------------------------------------------------------- parol
# Backlot-un öz autentifikasiyası YOXDUR. Parolsuz açıq qoymaq bütün
# istehsalat fayllarını internetə açmaq deməkdir — ona görə nginx səviyyəsində bağlayırıq.
HTPASSWD=/etc/nginx/.backlot-htpasswd
if [ ! -f "$HTPASSWD" ]; then
    AUTH_PASS="$(openssl rand -base64 18)"
    htpasswd -bc "$HTPASSWD" "$AUTH_USER" "$AUTH_PASS" >/dev/null 2>&1
    chown root:www-data "$HTPASSWD"; chmod 640 "$HTPASSWD"
    NEW_PASS=1
else
    NEW_PASS=0
fi

# ----------------------------------------------------------------------- nginx
say "nginx reverse proxy"
SERVER_NAME="${DOMAIN:-_}"
cat > /etc/nginx/sites-available/backlot <<NGINX
server {
    listen 80;
    server_name $SERVER_NAME;

    # Lövhə base64 data deyil, şəkil sürüşdürür — bədən limitini geniş saxla.
    client_max_body_size 64m;

    location / {
        auth_basic           "Backlot";
        auth_basic_user_file $HTPASSWD;

        proxy_pass http://127.0.0.1:$PORT;
        proxy_set_header Host              \$host;
        proxy_set_header X-Real-IP         \$remote_addr;
        proxy_set_header X-Forwarded-For   \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        # --- SSE: lövhənin CANLI qalması bu dörd sətirdən asılıdır ---
        # Buferləmə açıq qalsa nginx hadisə axınını tutub saxlayır və
        # lövhə yenilənmir; oxuma vaxtı qısa olsa axın hər dəfə qırılır.
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_buffering off;
        chunked_transfer_encoding off;
        proxy_read_timeout 1h;
    }
}
NGINX

ln -sf /etc/nginx/sites-available/backlot /etc/nginx/sites-enabled/backlot
[ -e /etc/nginx/sites-enabled/default ] && rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl reload nginx
ok "nginx yükləndi"

# ------------------------------------------------------------------------ TLS
if [ -n "$DOMAIN" ]; then
    say "TLS sertifikatı ($DOMAIN)"
    apt-get install -y -qq certbot python3-certbot-nginx
    if certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos \
               --register-unsafely-without-email --redirect; then
        ok "HTTPS aktivdir"
        URL="https://$DOMAIN"
    else
        warn "certbot uğursuz oldu (DNS hələ yayılmayıb?) — hələlik HTTP ilə davam edir"
        URL="http://$DOMAIN"
    fi
else
    IP="$(curl -fsS --max-time 10 https://api.ipify.org 2>/dev/null || hostname -I | awk '{print $1}')"
    URL="http://$IP"
    warn "DOMAIN verilmədi — TLS yoxdur, parol şifrələnməmiş gedir."
    warn "Domen bağlayıb skripti DOMAIN=... ilə təkrar işlət."
fi

# --------------------------------------------------------------- nümunə layihə
if [ ! -d "$APP_DIR/projects/ademos-demo" ]; then
    say "Nümunə istehsalat yaradılır"
    # Upstream bug: simulyator 'proposal' mərhələsini atlayır, checkpoint validasiyası düşür.
    python3 - "$APP_DIR/scripts/backlot_simulate_run.py" <<'PATCH'
import re, sys, pathlib
p = pathlib.Path(sys.argv[1]); s = p.read_text()
if 'cp("proposal"' not in s:
    rx = re.compile(r'^([ \t]*)# script gates: awaiting_human -> approved', re.M)
    if rx.search(s):
        p.write_text(rx.sub(
            r'\1# proposal (məcburi ön şərt)\n'
            r'\1cp("proposal", "in_progress", {})\n'
            r'\1proposal = sample_artifact("proposal_packet")\n'
            r'\1save_artifact("proposal_packet", proposal)\n'
            r'\1cp("proposal", "completed", {"proposal_packet": proposal}, human_approved=True)\n\n'
            r'\1# script gates: awaiting_human -> approved', s, count=1))
        print("    simulyator düzəldildi")
PATCH
    sudo -u "$SERVICE_USER" env HOME="/home/$SERVICE_USER" \
        "$APP_DIR/.venv/bin/python" "$APP_DIR/scripts/backlot_simulate_run.py" \
        --project ademos-demo --fast || warn "demo yaradıla bilmədi — kitabxana boş açılacaq"
fi

# ---------------------------------------------------------------------- xülasə
say "Hazırdır"
echo
echo "    Lövhə:      $URL/p/ademos-demo"
echo "    Kitabxana:  $URL/"
echo "    İstifadəçi: $AUTH_USER"
if [ "$NEW_PASS" = "1" ]; then
    echo "    Parol:      $AUTH_PASS"
    echo
    warn "Bu parol bir dəfə göstərilir — indi saxla."
else
    echo "    Parol:      (əvvəlki qurulumdan saxlanılıb)"
    echo "    Sıfırlamaq: htpasswd -c $HTPASSWD $AUTH_USER"
fi
echo
echo "    Servis:     systemctl status backlot"
echo "    Loglar:     journalctl -u backlot -f"
echo

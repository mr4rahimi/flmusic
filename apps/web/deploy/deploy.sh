#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# دیپلوی نسخه‌ی وب flmusic.ir
#
# طراحی شده برای سروری که سایت‌های دیگری هم روی آن است:
#   • فقط داخل /opt/music-platform/apps/web کار می‌کند
#   • فقط پروسه‌ی PM2 با نام music_web را دست می‌زند
#   • هیچ فایلی خارج از مسیر خودش پاک نمی‌کند
#   • دیپلوی اتمیک است: نسخه‌ی جدید کنار قبلی می‌نشیند و در آخر
#     symlink «current» جابه‌جا می‌شود، پس زمان قطعی نزدیک صفر است
#   • با ./deploy.sh rollback به نسخه‌ی قبلی برمی‌گردیم
#
# استفاده:
#   ./deploy.sh              دیپلوی کامل (build + آپلود + راه‌اندازی)
#   ./deploy.sh rollback     بازگشت به نسخه‌ی قبلی
#   ./deploy.sh status       وضعیت سرویس و نسخه‌ی فعال
#   ./deploy.sh nginx        نصب/به‌روزرسانی کانفیگ nginx (با تست قبل از reload)
#   ./deploy.sh ssl          گرفتن گواهی Let's Encrypt و فعال‌کردن HTTPS
#
# احراز هویت SSH: کلید عمومی توصیه می‌شود.
#   ssh-copy-id root@185.164.73.224
# اگر رمز عبور لازم است، sshpass نصب کنید و SSHPASS را در محیط بگذارید:
#   export SSHPASS='...'
# ---------------------------------------------------------------------------
set -Eeuo pipefail

# --- تنظیمات (قابل بازنویسی با متغیر محیطی) -------------------------------
SSH_HOST="${SSH_HOST:-185.164.73.224}"
SSH_USER="${SSH_USER:-root}"
SSH_PORT="${SSH_PORT:-22}"

REMOTE_ROOT="${REMOTE_ROOT:-/opt/music-platform/apps/web}"
PM2_NAME="${PM2_NAME:-music_web}"
APP_PORT="${APP_PORT:-3006}"
KEEP_RELEASES="${KEEP_RELEASES:-5}"

NGINX_SITE="${NGINX_SITE:-flmusic.ir}"
DOMAIN="${DOMAIN:-flmusic.ir}"
CERT_EMAIL="${CERT_EMAIL:-shiralat.top@gmail.com}"
# همان مسیری که سایت‌های دیگر این سرور برای چالش ACME استفاده می‌کنند
WEBROOT="${WEBROOT:-/var/www/certbot}"

# آدرس API هنگام build.
# .env.production آدرس داخلی 127.0.0.1:3000 را دارد که فقط روی خود سرور
# معنا دارد؛ اما build روی ماشین توسعه انجام می‌شود و صفحات ثابت همان‌جا
# prerender می‌شوند. اگر این آدرس در دسترس نباشد، sitemap و صفحات
# فهرست خالی ساخته می‌شوند بدون اینکه build شکست بخورد.
BUILD_API_URL="${BUILD_API_URL:-http://185.164.73.224/api/v1}"

# --- مسیرها ---------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(dirname "$SCRIPT_DIR")"

RELEASE_ID="$(date +%Y%m%d-%H%M%S)"
REMOTE_RELEASES="$REMOTE_ROOT/releases"
REMOTE_CURRENT="$REMOTE_ROOT/current"
REMOTE_RELEASE="$REMOTE_RELEASES/$RELEASE_ID"

# --- خروجی رنگی -----------------------------------------------------------
c_info()  { printf '\033[36m▸ %s\033[0m\n' "$*"; }
c_ok()    { printf '\033[32m✓ %s\033[0m\n' "$*"; }
c_warn()  { printf '\033[33m! %s\033[0m\n' "$*"; }
c_err()   { printf '\033[31m✗ %s\033[0m\n' "$*" >&2; }

trap 'c_err "دیپلوی در خط $LINENO متوقف شد. نسخه‌ی فعال روی سرور دست‌نخورده است."' ERR

# --- پوسته‌ی SSH ----------------------------------------------------------
# اگر SSHPASS ست باشد و sshpass نصب باشد، از آن استفاده می‌کنیم.
if [[ -n "${SSHPASS:-}" ]] && command -v sshpass >/dev/null 2>&1; then
  SSH_WRAP=(sshpass -e)
else
  SSH_WRAP=()
fi

ssh_run() {
  "${SSH_WRAP[@]}" ssh -p "$SSH_PORT" \
    -o StrictHostKeyChecking=accept-new \
    -o ConnectTimeout=15 \
    "$SSH_USER@$SSH_HOST" "$@"
}

scp_put() {
  "${SSH_WRAP[@]}" scp -P "$SSH_PORT" \
    -o StrictHostKeyChecking=accept-new \
    -o ConnectTimeout=15 \
    "$1" "$SSH_USER@$SSH_HOST:$2"
}

# --- بررسی‌های پیش از شروع ------------------------------------------------
preflight() {
  c_info "بررسی پیش‌نیازها…"

  [[ -f "$APP_DIR/package.json" ]] || { c_err "package.json پیدا نشد: $APP_DIR"; exit 1; }
  [[ -f "$APP_DIR/.env.production" ]] || {
    c_err ".env.production وجود ندارد. از .env.example کپی و مقداردهی کنید."
    exit 1
  }

  # Next فایل‌های .env.local و .env.production.local را در بیلد production
  # هم می‌خواند و روی .env.production را می‌پوشانند. اگر وجود داشته باشند،
  # آدرس‌های canonical و sitemap با مقادیر لوکال ساخته می‌شوند.
  for leak in .env.local .env.production.local; do
    if [[ -f "$APP_DIR/$leak" ]]; then
      c_err "$leak وجود دارد و مقادیر .env.production را می‌پوشاند."
      c_warn "نامش را به .env.development.local تغییر دهید."
      exit 1
    fi
  done

  command -v pnpm >/dev/null || { c_err "pnpm نصب نیست"; exit 1; }
  command -v tar  >/dev/null || { c_err "tar نصب نیست"; exit 1; }

  ssh_run true || { c_err "اتصال SSH به $SSH_USER@$SSH_HOST برقرار نشد"; exit 1; }
  ssh_run "command -v pm2 >/dev/null" || { c_err "pm2 روی سرور نصب نیست"; exit 1; }
  ssh_run "command -v node >/dev/null" || { c_err "node روی سرور نصب نیست"; exit 1; }

  # API باید هنگام build در دسترس باشد وگرنه صفحات با داده‌ی خالی ساخته می‌شوند
  local probe
  probe="$(curl -s -o /dev/null -w '%{http_code}' -m 15 "$BUILD_API_URL/feed/new?limit=1" || true)"
  if [[ "$probe" != "200" ]]; then
    c_err "API هنگام build در دسترس نیست: $BUILD_API_URL (کد ${probe:-timeout})"
    c_warn "با BUILD_API_URL=... آدرس درست را بدهید."
    exit 1
  fi

  # اطمینان از اینکه پورت انتخاب‌شده را سرویس دیگری اشغال نکرده
  if ssh_run "ss -ltn 2>/dev/null | grep -q ':$APP_PORT '"; then
    if ssh_run "pm2 pid $PM2_NAME >/dev/null 2>&1"; then
      c_info "پورت $APP_PORT در اختیار $PM2_NAME است (دیپلوی مجدد)."
    else
      c_err "پورت $APP_PORT را سرویس دیگری گرفته است. APP_PORT را عوض کنید."
      exit 1
    fi
  fi

  c_ok "پیش‌نیازها تأیید شد"
}

# --- ساخت -----------------------------------------------------------------
build() {
  c_info "نصب وابستگی‌ها…"
  ( cd "$APP_DIR" && pnpm install --frozen-lockfile --child-concurrency=1 )

  c_info "بررسی نوع‌ها و lint…"
  ( cd "$APP_DIR" && npx tsc --noEmit && npx eslint src --max-warnings=0 )

  c_info "ساخت نسخه‌ی production…"
  # API_INTERNAL_URL را فقط برای همین دستور بازنویسی می‌کنیم؛ روی سرور
  # مقدار داخلی از ecosystem.config.js می‌آید.
  ( cd "$APP_DIR" && rm -rf .next \
      && NODE_ENV=production API_INTERNAL_URL="$BUILD_API_URL" pnpm build )

  [[ -f "$APP_DIR/.next/standalone/server.js" ]] || {
    c_err "خروجی standalone ساخته نشد. output:'standalone' در next.config.ts لازم است."
    exit 1
  }

  c_ok "ساخت انجام شد"
}

# --- بسته‌بندی ------------------------------------------------------------
# خروجی standalone فایل‌های static و public را در خود ندارد؛ باید کنارش گذاشته شوند.
package() {
  c_info "بسته‌بندی…"

  # trap ... RETURN اینجا کار نمی‌کند چون در دامنه‌ی تابع فراخوان هم
  # آتش می‌گیرد؛ پوشه را در پایان همین تابع دستی پاک می‌کنیم.
  local stage
  stage="$(mktemp -d)"

  cp -r "$APP_DIR/.next/standalone/." "$stage/"
  mkdir -p "$stage/.next"
  cp -r "$APP_DIR/.next/static" "$stage/.next/static"
  [[ -d "$APP_DIR/public" ]] && cp -r "$APP_DIR/public" "$stage/public"

  # فونت‌های تولید تصویر OpenGraph در زمان اجرا از دیسک خوانده می‌شوند
  [[ -d "$APP_DIR/assets" ]] && cp -r "$APP_DIR/assets" "$stage/assets"

  # متغیرهای زمان اجرا (مثل API_INTERNAL_URL) کنار server.js لازم‌اند
  cp "$APP_DIR/.env.production" "$stage/.env.production"

  TARBALL="$(mktemp -t flmusic-web-XXXXXX.tar.gz)"
  tar -czf "$TARBALL" -C "$stage" .
  rm -rf "$stage"

  c_ok "بسته آماده شد ($(du -h "$TARBALL" | cut -f1))"
}

# --- انتشار ---------------------------------------------------------------
release() {
  c_info "آپلود به $REMOTE_RELEASE…"

  ssh_run "mkdir -p '$REMOTE_RELEASE'"
  scp_put "$TARBALL" "$REMOTE_RELEASE/release.tar.gz"
  ssh_run "tar -xzf '$REMOTE_RELEASE/release.tar.gz' -C '$REMOTE_RELEASE' && rm -f '$REMOTE_RELEASE/release.tar.gz'"

  c_info "جابه‌جایی symlink به نسخه‌ی جدید…"
  # -n و -f با هم: symlink موجود را جایگزین کن، نه اینکه داخلش بساز
  ssh_run "ln -sfn '$REMOTE_RELEASE' '$REMOTE_CURRENT'"

  c_info "راه‌اندازی PM2…"
  scp_put "$SCRIPT_DIR/ecosystem.config.js" "$REMOTE_ROOT/ecosystem.config.js"
  ssh_run "cd '$REMOTE_ROOT' && (pm2 reload '$PM2_NAME' --update-env || pm2 start ecosystem.config.js) && pm2 save"

  c_ok "نسخه‌ی $RELEASE_ID فعال شد"
}

# --- بررسی سلامت ----------------------------------------------------------
verify() {
  c_info "بررسی سلامت…"

  local code=""
  for _ in $(seq 1 20); do
    code="$(ssh_run "curl -s -o /dev/null -w '%{http_code}' -m 5 http://127.0.0.1:$APP_PORT/ || true")"
    [[ "$code" == "200" ]] && break
    sleep 2
  done

  if [[ "$code" != "200" ]]; then
    c_err "سرویس پاسخ ۲۰۰ نداد (کد: ${code:-timeout})."
    c_warn "برای بازگشت: ./deploy.sh rollback"
    ssh_run "pm2 logs '$PM2_NAME' --lines 30 --nostream || true"
    exit 1
  fi

  c_ok "سرویس سالم است (HTTP 200)"

  # سلامت SEO: این سه مسیر باید همیشه کار کنند
  for path in /robots.txt /sitemap.xml /new; do
    local c
    c="$(ssh_run "curl -s -o /dev/null -w '%{http_code}' -m 10 http://127.0.0.1:$APP_PORT$path || true")"
    [[ "$c" == "200" ]] && c_ok "  $path → $c" || c_warn "  $path → $c"
  done

  # آدرس‌های canonical باید روی دامنه‌ی واقعی باشند، نه localhost.
  # اگر متغیرهای محیطی هنگام build اشتباه باشند، سایت بالا می‌آید ولی
  # همه‌ی سیگنال‌های SEO به آدرس بی‌معنی اشاره می‌کنند.
  local host
  host="$(ssh_run "curl -s -m 10 http://127.0.0.1:$APP_PORT/robots.txt | grep -i '^Sitemap:' || true")"
  if grep -qi 'localhost\|127\.0\.0\.1' <<<"$host"; then
    c_err "آدرس canonical روی localhost ساخته شده: $host"
    c_warn "NEXT_PUBLIC_SITE_URL هنگام build اشتباه بوده. .env.production را چک کنید."
    exit 1
  fi
  c_ok "  canonical → ${host:-نامشخص}"

  # sitemap باید واقعاً محتوا داشته باشد. اگر API هنگام build جواب نداده
  # باشد، sitemap فقط چند صفحه‌ی ثابت دارد و عملاً بی‌فایده است.
  local track_count
  track_count="$(ssh_run "curl -s -m 20 http://127.0.0.1:$APP_PORT/sitemap.xml | grep -c '/track/' || true")"
  if [[ "${track_count:-0}" -lt 1 ]]; then
    c_err "sitemap هیچ صفحه‌ی آهنگی ندارد — API هنگام build جواب نداده است."
    exit 1
  fi
  c_ok "  sitemap → ${track_count} آهنگ"
}

# --- پاکسازی نسخه‌های قدیمی ------------------------------------------------
prune() {
  c_info "نگه‌داشتن $KEEP_RELEASES نسخه‌ی آخر…"
  # فقط داخل پوشه‌ی releases خودمان — با محافظ در برابر مسیر خالی
  ssh_run "set -e
    dir='$REMOTE_RELEASES'
    case \"\$dir\" in /opt/music-platform/apps/web/releases) ;; *) echo 'مسیر نامعتبر'; exit 1;; esac
    cd \"\$dir\"
    ls -1t | tail -n +\$(( $KEEP_RELEASES + 1 )) | while read -r old; do
      [ -n \"\$old\" ] && [ -d \"\$old\" ] && rm -rf -- \"\$old\"
    done"
  c_ok "پاکسازی انجام شد"
}

# --- دستورها --------------------------------------------------------------
cmd_deploy() {
  preflight
  build
  package
  release
  verify
  prune
  c_ok "دیپلوی کامل شد → https://flmusic.ir"
  rm -f "$TARBALL"
}

cmd_rollback() {
  c_info "بازگشت به نسخه‌ی قبلی…"

  local previous
  previous="$(ssh_run "ls -1t '$REMOTE_RELEASES' 2>/dev/null | sed -n 2p")"
  [[ -n "$previous" ]] || { c_err "نسخه‌ی قبلی وجود ندارد"; exit 1; }

  ssh_run "ln -sfn '$REMOTE_RELEASES/$previous' '$REMOTE_CURRENT' && pm2 reload '$PM2_NAME' --update-env"
  verify
  c_ok "به نسخه‌ی $previous برگشتیم"
}

cmd_status() {
  echo "— نسخه‌ی فعال —"
  ssh_run "readlink -f '$REMOTE_CURRENT' 2>/dev/null || echo 'هنوز دیپلوی نشده'"
  echo
  echo "— نسخه‌های موجود —"
  ssh_run "ls -1t '$REMOTE_RELEASES' 2>/dev/null || echo '—'"
  echo
  echo "— PM2 —"
  ssh_run "pm2 describe '$PM2_NAME' 2>/dev/null | grep -E 'status|uptime|restarts|memory' || echo 'پروسه وجود ندارد'"
}

cmd_nginx() {
  c_info "نصب کانفیگ nginx برای $NGINX_SITE…"

  scp_put "$SCRIPT_DIR/nginx-flmusic.conf" "/tmp/$NGINX_SITE.conf"

  # پشتیبان از کانفیگ فعلی، تست، و فقط در صورت موفقیت reload.
  # اگر تست شکست بخورد کانفیگ قبلی برمی‌گردد تا سایت‌های دیگر آسیب نبینند.
  ssh_run "set -e
    site='/etc/nginx/sites-available/$NGINX_SITE'
    if [ -f \"\$site\" ]; then cp \"\$site\" \"\$site.bak.\$(date +%s)\"; fi
    mv '/tmp/$NGINX_SITE.conf' \"\$site\"
    ln -sfn \"\$site\" '/etc/nginx/sites-enabled/$NGINX_SITE'
    if nginx -t; then
      systemctl reload nginx
      echo 'nginx reloaded'
    else
      rm -f '/etc/nginx/sites-enabled/$NGINX_SITE'
      echo 'تست nginx شکست خورد — کانفیگ غیرفعال شد و nginx دست‌نخورده ماند' >&2
      exit 1
    fi"

  c_ok "nginx به‌روزرسانی شد"
}

# --- گرفتن گواهی SSL ------------------------------------------------------
# کانفیگ اصلی به /etc/letsencrypt/live/<domain>/ ارجاع می‌دهد، پس تا وقتی
# گواهی وجود ندارد `nginx -t` رد می‌شود. این تابع ترتیب درست را رعایت می‌کند:
# اول یک بلوک موقت فقط-HTTP برای چالش ACME، بعد گرفتن گواهی، بعد کانفیگ کامل.
cmd_ssl() {
  c_info "گرفتن گواهی Let's Encrypt برای $DOMAIN…"

  ssh_run "command -v certbot >/dev/null" || {
    c_err "certbot روی سرور نصب نیست"
    exit 1
  }

  # اگر گواهی معتبر از قبل هست، دوباره نمی‌گیریم (سقف نرخ Let's Encrypt)
  if ssh_run "certbot certificates 2>/dev/null | grep -q 'Certificate Name: $DOMAIN$'"; then
    c_ok "گواهی $DOMAIN از قبل وجود دارد"
  else
    c_info "نصب بلوک موقت HTTP برای چالش ACME…"

    # این فایل فقط server_name خودمان را می‌گیرد و default_server ندارد،
    # پس در این فاصله هیچ دامنه‌ی دیگری تحت تأثیر نیست.
    ssh_run "set -e
      mkdir -p '$WEBROOT/.well-known/acme-challenge'
      site='/etc/nginx/sites-available/$NGINX_SITE'
      if [ -f \"\$site\" ]; then cp \"\$site\" \"\$site.bak.\$(date +%s)\"; fi
      cat > \"\$site\" <<'CONF'
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN www.$DOMAIN;

    location ^~ /.well-known/acme-challenge/ {
        root $WEBROOT;
        default_type \"text/plain\";
    }

    location / {
        proxy_pass http://127.0.0.1:$APP_PORT;
        proxy_http_version 1.1;
        proxy_set_header Host       \$host;
        proxy_set_header Connection \"\";
    }
}
CONF
      ln -sfn \"\$site\" '/etc/nginx/sites-enabled/$NGINX_SITE'
      nginx -t && systemctl reload nginx"

    c_ok "بلوک موقت فعال شد"

    c_info "درخواست گواهی (روش webroot)…"
    ssh_run "certbot certonly --webroot -w '$WEBROOT' \
      -d '$DOMAIN' -d 'www.$DOMAIN' \
      --email '$CERT_EMAIL' --agree-tos --no-eff-email \
      --non-interactive --keep-until-expiring" || {
      c_err "گرفتن گواهی شکست خورد."
      c_warn "معمول‌ترین علت: DNS هنوز به این سرور اشاره نمی‌کند یا CDN روشن است."
      exit 1
    }

    c_ok "گواهی صادر شد"
  fi

  # حالا که گواهی هست، کانفیگ کامل با بلوک ۴۴۳ نصب می‌شود
  cmd_nginx

  c_info "بررسی HTTPS…"
  local code
  code="$(ssh_run "curl -s -o /dev/null -w '%{http_code}' -m 15 --resolve '$DOMAIN:443:127.0.0.1' 'https://$DOMAIN/' || true")"
  [[ "$code" == "200" ]] && c_ok "https://$DOMAIN → $code" || c_warn "https://$DOMAIN → ${code:-timeout}"

  c_info "تمدید خودکار…"
  ssh_run "systemctl list-timers certbot.timer --no-pager 2>/dev/null | tail -2 || echo 'تایمر certbot پیدا نشد'"
}

case "${1:-deploy}" in
  deploy)   cmd_deploy ;;
  rollback) cmd_rollback ;;
  status)   cmd_status ;;
  nginx)    cmd_nginx ;;
  ssl)      cmd_ssl ;;
  *)
    c_err "دستور ناشناخته: $1"
    echo "استفاده: $0 [deploy|rollback|status|nginx|ssl]"
    exit 1
    ;;
esac

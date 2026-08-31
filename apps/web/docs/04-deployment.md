# دیپلوی

## وضعیت فعلی سرور

> **این سرور مشترک است.** روی آن دست‌کم ۹ سرویس PM2 و ۱۳ سایت nginx
> دیگر اجرا می‌شود. هر تغییری باید محدود به دارایی‌های همین پروژه بماند.

```
185.164.73.224
├── nginx                    ← درگاه ورودی، ۱۳ سایت دیگر هم دارد
├── PostgreSQL (5432)  ·  Redis (6379)
├── PM2
│   ├── music_api            (پورت 3000)  NestJS  ← دست نزنید
│   ├── music_web            (پورت 3006)  ← این پروژه
│   └── 9dm, bartar-crm, bartarjanebi, istgahedandan,
│       mahamprinter, modi, price-next, robehrah-demo  ← دست نزنید
└── /opt/music-platform/
    └── apps/
        ├── api/
        └── web/             ← این پروژه
            ├── releases/
            │   ├── 20260826-153000/
            │   └── 20260826-161200/
            ├── current -> releases/20260826-161200
            └── ecosystem.config.js
```

### پورت‌ها

پورت‌های اشغال‌شده هنگام راه‌اندازی این پروژه:

| پورت | سرویس |
|---|---|
| 3000 | `music_api` (NestJS) |
| 3001 | bartarjanebi |
| 3002 | mahamprinter |
| 3003 | 9dm |
| 3004 | istgahedandan |
| 3005 | price-next |
| 3010, 3020, 3030 | modi، bartar-crm، robehrah-demo |
| **3006** | **`music_web` — این پروژه** |

اولین انتخاب ۳۰۰۱ بود که اشغال بود. مرحله‌ی `preflight` اسکریپت دیپلوی
دقیقاً برای همین وجود دارد: اگر پورت را سرویس دیگری گرفته باشد،
**قبل از هر تغییری** متوقف می‌شود.

### دامنه و SSL

`flmusic.ir` و `www.flmusic.ir` مستقیم به `185.164.73.224` اشاره می‌کنند.
CDN پارس‌پک **خاموش** است.

TLS روی خود سرور با Let's Encrypt تمام می‌شود:

```
/etc/letsencrypt/live/flmusic.ir/fullchain.pem
/etc/letsencrypt/live/flmusic.ir/privkey.pem
```

گرفتن یا تمدید دستی:

```bash
./deploy/deploy.sh ssl
```

این دستور ترتیب درست را رعایت می‌کند و اگر گواهی معتبر از قبل باشد
دوباره درخواست نمی‌دهد (سقف نرخ Let's Encrypt). تمدید خودکار را
certbot با تایمر systemd خودش انجام می‌دهد.

روش صدور **webroot** با مسیر `/var/www/certbot` است — همان روشی که
سایت‌های دیگر این سرور استفاده می‌کنند، تا همه یکدست بمانند.

> **گواهی قدیمی `/etc/ssl/flmusic/` را استفاده نکنید** — منقضی شده و
> فقط بلوک ۴۴۳ سایت `api.flmusic.ir` هنوز به آن ارجاع می‌دهد.

#### چرا `listen 443 ssl http2` و نه `http2 on`؟

این سرور nginx **1.24** دارد. دستور `http2 on;` از nginx 1.25 اضافه شده
و روی 1.24 خطای `unknown directive` می‌دهد.

#### چرا ریدایرکت HTTPS شرطی است؟

بلوک پورت ۸۰ فقط وقتی به HTTPS ریدایرکت می‌کند که هدر
`X-Forwarded-Proto: https` نداشته باشد. اگر روزی دوباره پشت CDN رفت و
CDN با HTTP به origin وصل شد، این شرط جلوی حلقه‌ی بی‌نهایت را می‌گیرد.

### سایت‌های nginx موجود

`0fx.ir`, `8fx.ir`, `9dm`, `9fx.ir`, `api.9fx.ir`, `bartarjanebi`,
`default`, `demo.robehrah.ir`, `istgahedandan.ir`, `mahamprinter.com`,
`modi`, `music-api`, `robehrah.ir`

کانفیگ ما با نام `flmusic.ir` اضافه می‌شود و با هیچ‌کدام تداخل ندارد.
`music-api` که از قبل هست، `api.flmusic.ir` و IP خام را به پورت ۳۰۰۰
می‌فرستد و دست‌نخورده می‌ماند.

> **مهم:** هرگز `pm2 restart all`، `pm2 delete all` یا
> `systemctl restart nginx` اجرا نکنید — همه‌ی سایت‌های دیگر را می‌خواباند.
> برای nginx فقط `reload` و فقط بعد از `nginx -t`.

## اسکریپت دیپلوی

```bash
cd apps/web

./deploy/deploy.sh              # دیپلوی کامل
./deploy/deploy.sh status       # نسخه‌ی فعال و وضعیت PM2
./deploy/deploy.sh rollback     # بازگشت به نسخه‌ی قبلی
./deploy/deploy.sh nginx        # نصب/به‌روزرسانی کانفیگ nginx
```

### چه اتفاقی می‌افتد

۱. **preflight** — اتصال SSH، وجود `pm2`/`node` روی سرور، و اینکه
   پورت ۳۰۰۱ را سرویس دیگری نگرفته باشد.
۲. **build** — `pnpm install --frozen-lockfile`، سپس `tsc --noEmit` و
   `eslint`، سپس build. اگر هرکدام شکست بخورد، هیچ‌چیز به سرور نمی‌رود.
۳. **package** — خروجی standalone + `.next/static` + `public` +
   `.env.production` در یک tarball.
۴. **release** — باز کردن در `releases/<timestamp>/` (کنار نسخه‌ی فعلی،
   نه روی آن).
۵. **switch** — `ln -sfn` روی `current`. این یک عملیات اتمیک است؛
   قطعی عملاً صفر.
۶. **verify** — تا ۴۰ ثانیه منتظر پاسخ ۲۰۰ روی `127.0.0.1:3001` می‌ماند و
   `/robots.txt`، `/sitemap.xml` و `/new` را هم چک می‌کند. اگر ناموفق
   باشد لاگ PM2 را نشان می‌دهد و پیشنهاد rollback می‌دهد.
۷. **prune** — فقط ۵ نسخه‌ی آخر نگه داشته می‌شود.

### چرا اتمیک؟

نسخه‌ی جدید در پوشه‌ی جدید باز می‌شود و تا لحظه‌ی جابه‌جایی symlink
هیچ ترافیکی نمی‌گیرد. اگر آپلود نیمه‌کاره بماند، سایت هنوز نسخه‌ی
سالم قبلی را سرو می‌کند.

### احراز هویت SSH

کلید عمومی توصیه می‌شود:

```bash
ssh-copy-id root@185.164.73.224
```

اگر رمز عبور لازم است:

```bash
sudo apt install sshpass
export SSHPASS='...'
./deploy/deploy.sh
```

### تنظیمات قابل بازنویسی

```bash
SSH_HOST=... SSH_USER=... APP_PORT=3007 KEEP_RELEASES=10 ./deploy/deploy.sh
BUILD_API_URL=http://185.164.73.224/api/v1 ./deploy/deploy.sh
```

## سه تله‌ای که در اولین دیپلوی خوردیم

مستند شده تا دفعه‌ی بعد وقت نگیرد. هر سه الان در اسکریپت گارد دارند.

### ۱. `.env.local` مقادیر پروداکشن را می‌پوشاند

Next فایل `.env.local` را **در بیلد production هم** می‌خواند و اولویتش
از `.env.production` بالاتر است. نتیجه: سایت بالا می‌آمد ولی همه‌ی
`canonical`ها و کل sitemap روی `http://localhost:3006` بودند — یعنی
از نظر SEO کاملاً بی‌خاصیت.

**راه‌حل:** فایل توسعه‌ی لوکال اسمش `.env.development.local` است
(فقط در `next dev` خوانده می‌شود). `preflight` اگر `.env.local` یا
`.env.production.local` ببیند، دیپلوی را متوقف می‌کند، و `verify`
هم چک می‌کند آدرس canonical روی localhost نباشد.

### ۲. build روی ماشین شما اجرا می‌شود، نه روی سرور

`.env.production` آدرس API را `127.0.0.1:3000` می‌گذارد که فقط روی خود
سرور معنا دارد. ولی صفحات ثابت هنگام `next build` روی لپ‌تاپ شما
prerender می‌شوند. آن فچ‌ها شکست می‌خوردند و — چون `apiGetSafe` خطا
نمی‌دهد — بیلد **موفق** بود با sitemap ۴ آدرسی و فهرست‌های خالی.

**راه‌حل:** `BUILD_API_URL` (پیش‌فرض `http://185.164.73.224/api/v1`)
فقط برای دستور build، `API_INTERNAL_URL` را بازنویسی می‌کند. روی سرور
مقدار داخلی از `ecosystem.config.js` می‌آید. `preflight` قبل از build
این آدرس را پینگ می‌کند و `verify` مطمئن می‌شود sitemap واقعاً
صفحه‌ی آهنگ دارد.

### ۳. پورت ۳۰۰۱ اشغال بود

انتخاب اولیه ۳۰۰۱ بود که `bartarjanebi` رویش نشسته بود. `preflight`
قبل از هر تغییری این را می‌گیرد.

### ۴. خاموش‌شدن CDN، دامنه را به سایت دیگری برد

تا وقتی CDN روشن بود، کانفیگ ما فقط پورت ۸۰ داشت و کافی بود. با خاموش
شدن CDN، دامنه مستقیم به سرور رسید و درخواست HTTPS روی ۴۴۳ افتاد —
جایی که ما بلوکی نداشتیم، پس `default_server` جوابش را داد و کاربر
سایت دیگری می‌دید.

**درس:** هر vhost باید هم ۸۰ و هم ۴۴۳ را پوشش دهد، حتی وقتی فکر می‌کنید
TLS جای دیگری تمام می‌شود.

### ۵. دیپلوی‌نکردن، شبیه باگ به نظر می‌رسد

بعد از بازطراحی رابط کاربری، سایت هنوز نسخه‌ی قدیمی را نشان می‌داد چون
تغییرات فقط لوکال بودند. `./deploy/deploy.sh status` نسخه‌ی فعال روی
سرور را نشان می‌دهد؛ قبل از دیباگ‌کردن «باگ»، اول این را چک کنید.

## اگر روزی دوباره CDN را روشن کردید

پارس‌پک با `wcdn-cache-policy: SMART` کش می‌کند و بعد از دیپلوی ممکن
است چند دقیقه نسخه‌ی قدیمی سرو شود.

تست مستقیم origin و دور زدن CDN:

```bash
curl -s -H "Host: flmusic.ir" http://185.164.73.224/ | grep canonical
```

اگر origin درست بود ولی دامنه غلط، فقط کش است — یا صبر کنید یا از پنل
پارس‌پک purge بزنید.

ریدایرکت شرطی HTTPS از قبل برای این حالت آماده است و حلقه نمی‌سازد.

## اولین دیپلوی — گام‌به‌گام

```bash
# ۱. مقادیر پروداکشن را چک کنید
cd apps/web
cat .env.production

# ۲. کانفیگ nginx را نصب کنید (یک‌بار)
./deploy/deploy.sh nginx

# ۳. دیپلوی
./deploy/deploy.sh

# ۴. راه‌اندازی خودکار PM2 پس از ریبوت (یک‌بار، روی سرور)
ssh root@185.164.73.224 'pm2 startup && pm2 save'
```

## کانفیگ nginx

فایل: [`deploy/nginx-flmusic.conf`](../deploy/nginx-flmusic.conf)

| مسیر | مقصد | کش |
|---|---|---|
| `/api/` | `127.0.0.1:3000` (NestJS) | — |
| `/uploads/` | `127.0.0.1:3000` | یک سال، immutable |
| `/_next/static/` | `127.0.0.1:3001` | یک سال، immutable |
| `/` | `127.0.0.1:3001` (Next.js) | مدیریت‌شده توسط Next |

### نکات ایمنی این کانفیگ

- `server_name` فقط `flmusic.ir` و `www.flmusic.ir` است. `default_server`
  ندارد، پس روی سایت‌های دیگر این سرور اثری نمی‌گذارد.
- دستور `nginx` در اسکریپت، قبل از reload از کانفیگ فعلی **پشتیبان**
  می‌گیرد و `nginx -t` می‌زند. اگر تست شکست بخورد، symlink را برمی‌دارد
  و nginx اصلاً reload نمی‌شود — سایت‌های دیگر سالم می‌مانند.
- **ریدایرکت اجباری HTTPS اینجا نیست.** CDN با HTTP به origin وصل می‌شود؛
  اگر nginx به HTTPS ریدایرکت کند، حلقه‌ی بی‌نهایت ایجاد می‌شود.
  اجبار HTTPS باید **در پنل پارس‌پک** فعال شود.

## دیپلوی تغییرات API

اگر `apps/api` را هم تغییر داده‌اید (مثل `feed/genres` و `feed/genre/:genre`
که برای صفحات خواننده اضافه شدند و هنوز مستقر نشده‌اند)، آن مسیر جداست:
روی سرور TypeScript کامپایل نمی‌شود و باید `dist` را patch کرد. جزئیات در
حافظه‌ی پروژه و [05-api-integration.md](05-api-integration.md).

### بعد از دیپلوی این نسخه

مسیرهای `/genre` و `/genre/:name` حالا ۳۰۸ می‌دهند. اگر پارس‌پک نسخه‌ی
قدیمی این صفحات را کش کرده، کش را purge کنید وگرنه گوگل تا انقضای کش
همان محتوای قدیمی را می‌بیند.

## عیب‌یابی

| نشانه | بررسی |
|---|---|
| ۵۰۲ از nginx | `pm2 describe music_web` — آیا بالا است؟ `ss -ltn \| grep 3001` |
| صفحه‌ها خالی‌اند | `API_INTERNAL_URL` درست است؟ `curl 127.0.0.1:3000/api/v1/feed/new` روی سرور |
| تصاویر لود نمی‌شوند | `NEXT_PUBLIC_MEDIA_URL` و `remotePatterns` در `next.config.ts` |
| متادیتا آدرس اشتباه دارد | `NEXT_PUBLIC_SITE_URL` هنگام build اشتباه بوده — build دوباره لازم است |
| بعد از دیپلوی محتوا قدیمی است | ISR هنوز منقضی نشده، یا CDN کش کرده. کش پارس‌پک را purge کنید |

لاگ‌ها:

```bash
ssh root@185.164.73.224 'pm2 logs music_web --lines 100 --nostream'
ssh root@185.164.73.224 'tail -50 /var/log/nginx/flmusic.error.log'
```

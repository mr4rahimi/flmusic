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

`flmusic.ir` روی CDN پارس‌پک (`185.239.1.100`) است و به این سرور اشاره
می‌کند. گواهی Let's Encrypt روی **لبه‌ی CDN** معتبر است (تا مهر ۱۴۰۵).

> **نکته:** گواهی روی خود سرور (`/etc/ssl/flmusic/`) در ۲۳ ژوئیه ۲۰۲۶
> **منقضی شده** است. کانفیگ ما فقط روی پورت ۸۰ گوش می‌دهد و CDN هم با
> HTTP به origin وصل می‌شود، پس این انقضا الان چیزی را نمی‌شکند.
> ولی بلوک ۴۴۳ سایت `api.flmusic.ir` از همان گواهی استفاده می‌کند و
> اتصال مستقیم HTTPS به آن زیردامنه خطا می‌دهد. تمدیدش کنید.

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

## کش CDN

پارس‌پک پاسخ‌ها را با `wcdn-cache-policy: SMART` کش می‌کند. بعد از
دیپلوی ممکن است نسخه‌ی قدیمی چند دقیقه سرو شود.

برای تست مستقیم origin و دور زدن CDN:

```bash
curl -s -H "Host: flmusic.ir" http://185.164.73.224/ | grep canonical
```

اگر origin درست بود ولی دامنه غلط، فقط کش CDN است — یا صبر کنید
یا از پنل پارس‌پک purge بزنید.

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

اگر `apps/api` را هم تغییر داده‌اید (مثل endpointهای ژانر که برای صفحات
سبک اضافه شد)، آن مسیر جداست: روی سرور TypeScript کامپایل نمی‌شود و
باید `dist` را patch کرد. جزئیات در حافظه‌ی پروژه و
[05-api-integration.md](05-api-integration.md).

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

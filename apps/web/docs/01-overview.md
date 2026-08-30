# اف ال موزیک (نسخه‌ی وب) — نمای کلی

## هدف

`apps/web` نسخه‌ی وب پلتفرم است، با نام برند **اف ال موزیک**
(`SITE_NAME` در [`src/lib/env.ts`](../src/lib/env.ts)) و تمرکز بر
**دیده‌شدن در گوگل**.

اپ موبایل **فندوق** (`apps/mobile`، Flutter) یک شبکه‌ی اجتماعی تخصصی
موسیقی است: آپلود آهنگ، لایک، پلی‌لیست شخصی، دنبال‌کردن، نظر و بازنشر.
محتوای آن برای موتور جستجو قابل خواندن نیست. اف ال موزیک همان محتوا را
به شکل HTML سرور-رندر منتشر می‌کند تا هر آهنگ، هر خواننده و هر سبک یک
صفحه‌ی قابل ایندکس داشته باشد.

پس تقسیم کار روشن است:

| | اف ال موزیک (وب) | فندوق (اپ) |
|---|---|---|
| نقش | ویترین عمومی و قابل ایندکس | شبکه‌ی اجتماعی و ابزار کاربر |
| شنیدن آهنگ | ✅ بدون لاگین | ✅ |
| آپلود، لایک، پلی‌لیست، دنبال‌کردن، نظر | ❌ | ✅ |

صفحه‌ی اصلی وب یک بخش معرفی اپ دارد
([`src/components/AppPromo.tsx`](../src/components/AppPromo.tsx)) که همین
امکانات را فهرست می‌کند. لینک دانلود از
`NEXT_PUBLIC_APP_DOWNLOAD_URL` می‌آید و تا وقتی خالی باشد دکمه رندر نمی‌شود.

## فاز فعلی (فاز ۱)

صفحات **عمومی و بدون نیاز به لاگین**:

| مسیر | توضیح | نوع رندر |
|---|---|---|
| `/` | صفحه‌ی اصلی: داغ‌ترین + جدیدترین | ISR (۵ دقیقه) |
| `/trending` | فهرست داغ‌ترین آهنگ‌ها | ISR (۵ دقیقه) |
| `/new` | فهرست جدیدترین آهنگ‌ها | ISR (۲ دقیقه) |
| `/artists` | فهرست خواننده‌ها | ISR (۱ ساعت) |
| `/artist/[name]` | آهنگ‌های یک خواننده | SSG + ISR (۱۰ دقیقه) |
| `/styles` | فهرست سبک‌ها | ISR (۱ ساعت) |
| `/style/[style]` | آهنگ‌های یک سبک | SSG + ISR (۱۰ دقیقه) |
| `/track/[slug--id]` | صفحه‌ی آهنگ | SSR + ISR (۵ دقیقه) |
| `/user/[username]` | پروفایل حساب کاربری | SSR |
| `/playlist/[slug--id]` | پلی‌لیست | SSR + ISR (۱۰ دقیقه) |
| `/search?q=` | جستجو | SSR، **noindex** |
| `/sitemap.xml` | نقشه‌ی سایت | ISR (۱ ساعت) |
| `/robots.txt` | robots | ثابت |

پخش صوت به‌صورت یک نوار پایین صفحه کار می‌کند و بین صفحات قطع نمی‌شود.

### در فاز ۱ نیست

لاگین، ثبت‌نام، آپلود، لایک، کامنت، دنبال‌کردن و نوتیفیکیشن.
API این‌ها را دارد ولی UI وب هنوز ندارد. توضیح در
[docs/06-roadmap.md](06-roadmap.md).

## پشته‌ی فنی

- **Next.js 16** (App Router) — رندر سمت سرور و متادیتای پویا
- **React 19**
- **Tailwind CSS 4**
- **TypeScript**
- فونت **Vazirmatn** از طریق `next/font` (خودمیزبان، بدون درخواست خارجی)

دیتا از همان NestJS موجود (`apps/api`) خوانده می‌شود؛ هیچ دیتابیس جدایی ندارد.

## راه‌اندازی محلی

```bash
cd apps/web
pnpm install
cp .env.example .env.local   # و مقادیر را تنظیم کنید
pnpm dev                     # http://localhost:3000
```

برای تست شبیه به پروداکشن:

```bash
pnpm build && PORT=3001 pnpm start
```

### متغیرهای محیطی

| متغیر | کاربرد |
|---|---|
| `NEXT_PUBLIC_SITE_URL` | مبنای canonical، sitemap و OpenGraph |
| `NEXT_PUBLIC_API_URL` | آدرس عمومی API |
| `API_INTERNAL_URL` | آدرس داخلی API برای فچ سمت سرور (روی سرور: `127.0.0.1:3000`) |
| `NEXT_PUBLIC_MEDIA_URL` | ریشه‌ی فایل‌های `uploads/` |
| `NEXT_PUBLIC_GOOGLE_SITE_VERIFICATION` | کد تأیید سرچ کنسول |
| `NEXT_PUBLIC_APP_DOWNLOAD_URL` | لینک دانلود اپ فندوق (اختیاری) |
| `REVALIDATE_SECONDS` | طول کش پیش‌فرض فچ‌ها |

> متغیرهای `NEXT_PUBLIC_*` هنگام **build** درون باندل نوشته می‌شوند.
> تغییرشان بدون build دوباره اثری ندارد.

## نقشه‌ی فایل‌ها

```
apps/web/
├── src/
│   ├── app/                    مسیرها (App Router)
│   │   ├── layout.tsx          html lang=fa dir=rtl، متادیتای پایه، JSON-LD سراسری
│   │   ├── robots.ts           تولید robots.txt
│   │   ├── sitemap.ts          تولید sitemap.xml
│   │   ├── manifest.ts         PWA manifest
│   │   ├── track/[id]/
│   │   │   ├── page.tsx
│   │   │   └── opengraph-image.tsx   تصویر پیش‌نمایش اشتراک‌گذاری
│   │   ├── artist/[name]/     آهنگ‌های یک خواننده
│   │   ├── artists/           فهرست خواننده‌ها
│   │   ├── style/[style]/     آهنگ‌های یک سبک
│   │   ├── styles/            فهرست سبک‌ها
│   │   ├── user/[username]/   پروفایل کاربر
│   │   └── ...
│   ├── components/             کامپوننت‌های مشترک
│   │   └── player/             نوار پخش (کلاینتی)
│   └── lib/
│       ├── env.ts              تنظیمات محیطی
│       ├── api.ts              کلاینت API
│       ├── types.ts            شکل داده‌های API
│       ├── seo.ts              ساخت URL، slug، متن متا
│       ├── jsonld.ts           سازنده‌های Schema.org
│       ├── og.tsx              کارت تصویر اشتراک‌گذاری
│       └── format.ts           قالب‌بندی فارسی
├── deploy/
│   ├── deploy.sh               اسکریپت دیپلوی اتمیک
│   ├── ecosystem.config.js     تنظیمات PM2
│   └── nginx-flmusic.conf      کانفیگ nginx
└── docs/                       همین مستندات
```

## سایر مستندات

- [۰۲ — استراتژی و پیاده‌سازی SEO](02-seo.md)
- [۰۳ — معماری و تصمیم‌های فنی](03-architecture.md)
- [۰۴ — دیپلوی](04-deployment.md)
- [۰۵ — اتصال به API](05-api-integration.md)
- [۰۶ — کارهای باقی‌مانده](06-roadmap.md)

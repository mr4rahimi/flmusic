# apps/web — اف ال موزیک

ویترین عمومی و سرور-رندرِ محتوای اپلیکیشن **فندوق**، با تمرکز بر SEO فارسی.
Next.js 16 (App Router) + React 19 + Tailwind 4.

هر آهنگ، هر خواننده و هر سبک یک صفحه‌ی قابل ایندکس دارد. کارهای تعاملی
(آپلود، لایک، پلی‌لیست شخصی، دنبال‌کردن، نظر) در اپ فندوق انجام می‌شود.

**زنده:** <https://flmusic.ir>

## شروع سریع

```bash
pnpm install
cp .env.example .env.development.local   # مقادیر را تنظیم کنید
pnpm dev                                  # http://localhost:3006
```

> فایل توسعه‌ی لوکال باید `.env.development.local` باشد، نه `.env.local` —
> دومی بیلد production را هم آلوده می‌کند. توضیح در
> [docs/04-deployment.md](docs/04-deployment.md).

## دستورها

```bash
pnpm dev                 اجرای توسعه روی پورت ۳۰۰۶
pnpm build               ساخت نسخه‌ی production
pnpm start               اجرای نسخه‌ی ساخته‌شده
pnpm check               بررسی نوع‌ها + lint
pnpm deploy              دیپلوی روی سرور
pnpm deploy:status       وضعیت نسخه‌ی فعال
pnpm deploy:rollback     بازگشت به نسخه‌ی قبلی
```

## مستندات

| سند | موضوع |
|---|---|
| [۰۱ — نمای کلی](docs/01-overview.md) | مسیرها، متغیرهای محیطی، نقشه‌ی فایل‌ها |
| [۰۲ — SEO](docs/02-seo.md) | ساختار URL، متادیتا، schema، چک‌لیست بعد از دیپلوی |
| [۰۳ — معماری](docs/03-architecture.md) | لایه‌بندی، تصمیم‌های فنی، نکات Next 16 |
| [۰۴ — دیپلوی](docs/04-deployment.md) | اسکریپت دیپلوی، nginx، تله‌های شناخته‌شده |
| [۰۵ — اتصال به API](docs/05-api-integration.md) | endpointها، شکل پاسخ‌ها، و **نگاشت خواننده/سبک/کاربر** |
| [۰۶ — کارهای باقی‌مانده](docs/06-roadmap.md) | فاز بعد و تصمیم‌های باز |

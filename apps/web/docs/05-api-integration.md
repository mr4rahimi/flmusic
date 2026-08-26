# اتصال به API

منبع همه‌ی داده‌ها: `apps/api` (NestJS)، با prefix سراسری `api/v1`.

## endpointهایی که وب استفاده می‌کند

| متد و مسیر | نیاز به لاگین | شکل پاسخ |
|---|---|---|
| `GET /feed/trending?page&limit` | خیر | `{ data, total, page, limit, totalPages }` |
| `GET /feed/new?page&limit` | خیر | همان |
| `GET /feed/genres` ★ | خیر | `[{ genre, count }]` |
| `GET /feed/genre/:genre?page&limit` ★ | خیر | مثل feed |
| `GET /tracks/:id` | خیر | موجودیت کامل `Track` + `user` |
| `GET /tracks/user/:username` | خیر | آرایه‌ی `Track` |
| `GET /profiles/:username` | خیر | `ProfileResponseDto` |
| `GET /playlists/:id` | خیر | `Playlist` + `tracks` |
| `GET /search?q&type&limit` | خیر | `{ data, total, page, limit }` |

★ = این دو در همین کار به API **اضافه شدند**. تا وقتی روی سرور مستقر
نشده‌اند، `getTracksByGenre` و `getGenres` به‌طور خودکار از روی
جدیدترین‌ها fallback می‌سازند، پس صفحات سبک خالی نمی‌مانند.

## سه شکل متفاوت پاسخ

این نکته‌ی مهمی است که در `toList()` مدیریت شده:

```ts
// آرایه‌ی خام
GET /tracks/user/:username  →  [ {...}, {...} ]

// آبجکت صفحه‌بندی
GET /feed/new               →  { data: [...], total, page, limit }

// آبجکت تودرتو
GET /search?type=all        →  { tracks: { data: [...] }, users: { data: [...] } }
```

برای همین در `search()` به‌جای `type=all` دو درخواست جدا با
`type=tracks` و `type=users` زده می‌شود — `type=all` هر بخش را به
۵ نتیجه محدود می‌کند و برای صفحه‌ی جستجو کافی نیست.

## تفاوت مهم: DTO در برابر موجودیت

`FeedService.buildPaginatedResult` یک DTO دستی می‌سازد که **فیلدهای
`visibility` و `status` را ندارد** — چون همان‌جا سمت سرور فیلتر شده‌اند.

نتیجه‌ی عملی: اگر روی خروجی feed فیلتر
`visibility === 'public' && status === 'ready'` بزنید، **همه‌چیز حذف می‌شود**.
به همین دلیل `onlyPublicReady()` فقط روی `/tracks/user/:username`
اعمال می‌شود که موجودیت کامل برمی‌گرداند.

در `types.ts` این دو فیلد اختیاری (`?`) تعریف شده‌اند تا همین واقعیت
در تایپ‌ها منعکس باشد.

## مسیر فایل‌های رسانه

مقادیر در دیتابیس **نسبی**اند:

```
coverUrl:  "uploads/covers/2b52eabc-....webp"
audioUrl:  "uploads/processed/7a7a3336-....mp3"
avatarUrl: "uploads/covers/2b52eabc-....webp"
```

`mediaUrl()` در `seo.ts` آن‌ها را به URL مطلق روی `NEXT_PUBLIC_MEDIA_URL`
تبدیل می‌کند و مقادیری که از قبل مطلق‌اند را دست‌نخورده می‌گذارد.

هر میزبان جدیدی که اضافه شود باید در `images.remotePatterns` داخل
`next.config.ts` هم ثبت شود، وگرنه `next/image` خطا می‌دهد.

## کش

هر فچ از طریق `apiGet` می‌رود که `next.revalidate` و `tags` را ست می‌کند:

| داده | برچسب | مدت |
|---|---|---|
| feed | `feed` | ۶۰–۳۰۰ ثانیه |
| آهنگ | `track:<id>` | ۳۰۰ ثانیه |
| پروفایل | `profile:<username>` | ۳۰۰ ثانیه |
| سبک‌ها | `genres` | ۳۶۰۰ ثانیه |
| جستجو | — | ۶۰ ثانیه |

برچسب‌ها آماده‌اند تا بعداً بتوان با `revalidateTag()` از داخل یک
webhook (مثلاً پس از آپلود آهنگ) کش را فوراً باطل کرد.

## دو مشکل API که باید بدانید

### ۱. نشت ایمیل در پروفایل عمومی

`GET /profiles/:username` بدون احراز هویت **ایمیل کاربر** را برمی‌گرداند:

```json
{ "username": "mr4rahimi", "email": "...", "avatarUrl": "..." }
```

`apps/api/src/modules/profiles/profiles.service.ts` → متد `getProfile`

نسخه‌ی وب این فیلد را **هرگز رندر نمی‌کند**، ولی هرکسی می‌تواند مستقیم
API را صدا بزند. با ایندکس‌شدن نام کاربری‌ها در گوگل، جمع‌آوری خودکار
ایمیل‌ها ساده‌تر می‌شود.

اصلاح پیشنهادی: `email` فقط وقتی برگردانده شود که
`currentUserId === user.id`. عمداً این تغییر را اعمال نکردم چون
اپ موبایل ممکن است به آن وابسته باشد و باید اول بررسی شود.

### ۲. فیلد `genre` نام خواننده را نگه می‌دارد

در داده‌ی فعلی مقادیر `genre` عبارت‌اند از «معین»، «هایده»، «داریوش» —
یعنی نام خواننده، نه سبک موسیقی. توضیح اثر آن بر SEO در
[02-seo.md](02-seo.md) بخش آخر.

## endpointهای اضافه‌شده به API

در `apps/api/src/modules/feed/`:

```ts
// feed.service.ts
getGenreFeed(genre, page, limit)   // آهنگ‌های یک سبک، مرتب بر اساس playCount
getGenres()                        // GROUP BY genre با تعداد

// feed.controller.ts
@Get('genres')        → getGenres()
@Get('genre/:genre')  → getGenreFeed()
```

هر دو **افزودنی**اند و هیچ رفتار موجودی را تغییر نمی‌دهند.

### مستقر کردنشان روی سرور

روی سرور TypeScript کامپایل نمی‌شود؛ باید `dist` را patch کرد:

```
/opt/music-platform/apps/api/dist/modules/feed/feed.service.js
/opt/music-platform/apps/api/dist/modules/feed/feed.controller.js
```

سپس:

```bash
pm2 restart music_api
```

تأیید:

```bash
curl http://127.0.0.1:3000/api/v1/feed/genres
```

تا وقتی این کار انجام نشده، صفحات سبک با fallback کار می‌کنند
(فقط از میان ۱۰۰ آهنگ اخیر می‌خوانند).

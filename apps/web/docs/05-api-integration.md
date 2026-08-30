# اتصال به API

منبع همه‌ی داده‌ها: `apps/api` (NestJS)، با prefix سراسری `api/v1`.

## endpointهایی که وب استفاده می‌کند

| متد و مسیر | نیاز به لاگین | شکل پاسخ |
|---|---|---|
| `GET /feed/trending?page&limit` | خیر | `{ data, total, page, limit, totalPages }` |
| `GET /feed/new?page&limit` | خیر | همان |
| `GET /feed/genres` ★ | خیر | `[{ genre, count }]` — در واقع **خواننده‌ها** |
| `GET /feed/genre/:genre?page&limit` ★ | خیر | مثل feed — آهنگ‌های یک **خواننده** |
| `GET /tracks/:id` | خیر | موجودیت کامل `Track` + `user` |
| `GET /tracks/user/:username` | خیر | آرایه‌ی `Track` |
| `GET /profiles/:username` | خیر | `ProfileResponseDto` |
| `GET /playlists/:id` | خیر | `Playlist` + `tracks` |
| `GET /search?q&type&limit` | خیر | `{ data, total, page, limit }` |

★ = این دو در همین کار به API **اضافه شدند** ولی **هنوز روی سرور مستقر
نشده‌اند** (`curl https://flmusic.ir/api/v1/feed/genres` → ۴۰۴). تا آن موقع
`getSingers()` و `getTracksBySinger()` به‌طور خودکار از روی نمونه‌ی
جدیدترین‌ها fallback می‌سازند، پس صفحات خالی نمی‌مانند. روش استقرار در
[بخش آخر همین سند](#مستقر-کردنشان-روی-سرور).

برای **سبک‌ها** هیچ endpointی وجود ندارد. `getStyles()` و
`getTracksByStyle()` اول `/feed/tags` و `/feed/tag/:tag` را امتحان می‌کنند
و بعد روی همان نمونه fallback می‌کنند.

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
| خواننده‌ها | `singers` | ۳۶۰۰ ثانیه |
| سبک‌ها | `styles` | ۳۶۰۰ ثانیه |
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

### ۲. فیلد `genre` نام خواننده را نگه می‌دارد، `tags` سبک را

این مهم‌ترین نکته‌ی این سند است.

```json
{ "title": "Ya Chi", "genre": "مسیح و آرش", "tags": ["عاشقانه"],
  "user": { "username": "qeshm" } }
```

- `genre` → **خواننده** («معین»، «هایده»، «مسیح و آرش»)
- `tags` → **سبک** («عاشقانه»، «غمگین»، «قدیمی»)
- `user.username` → **حساب کاربری‌ای که آهنگ را آپلود کرده** — نه لزوماً
  خواننده و نه لزوماً هنرمند

منشأ: فرم آپلود اپ فندوق فیلد «نام خواننده» را در ستون `genre` می‌فرستد —
[`upload_provider.dart`](../../mobile/lib/features/upload/presentation/providers/upload_provider.dart):

```dart
'genre': artistName,
if (tags != null && tags.isNotEmpty) 'tags': tags.join(','),
```

**قاعده‌ی وب:** هیچ کامپوننتی مستقیم `track.genre` یا `track.tags` را
نمی‌خواند. همه از دو helper در [`src/lib/types.ts`](../src/lib/types.ts)
استفاده می‌کنند:

```ts
singerOf(track)   // string | null  ← track.genre
stylesOf(track)   // string[]       ← track.tags
```

و نگاشت به مسیرها:

| مفهوم | فیلد API | تابع | مسیر |
|---|---|---|---|
| خواننده | `genre` | `singerOf` | `/artist/[name]` |
| سبک | `tags` | `stylesOf` | `/style/[name]` |
| کاربر | `user.username` | — | `/user/[username]` |

اگر روزی ستون‌ها در دیتابیس تغییر نام دادند، فقط همین دو helper و
توابع `getSingers/getStyles` در `api.ts` باید عوض شوند.

## endpointهای اضافه‌شده به API

در `apps/api/src/modules/feed/`:

```ts
// feed.service.ts
getGenreFeed(genre, page, limit)   // آهنگ‌های یک خواننده، مرتب بر اساس playCount
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

تا وقتی این کار انجام نشده، صفحات خواننده و سبک با fallback کار می‌کنند
(از میان ۳۰۰ آهنگ اخیر — ثابت `SAMPLE_SIZE` در `src/lib/api.ts`).
با رشد آرشیو، خواننده‌های قدیمی از فهرست می‌افتند؛ این تنها دلیلی است که
استقرار آن دو endpoint هنوز روی میز است.

### endpointهای پیشنهادی برای سبک‌ها

هم‌قواره‌ی دوتای بالا، ولی روی `tags` (که ستون آرایه است):

```
GET /feed/tags            → [{ tag, count }]
GET /feed/tag/:tag        → مثل feed
```

وب از قبل این دو را صدا می‌زند و اگر ۴۰۴ بگیرد fallback می‌کند، پس
افزودنشان به API هیچ تغییری در وب لازم ندارد.

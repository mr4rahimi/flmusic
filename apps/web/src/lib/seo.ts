import { MEDIA_URL, SITE_NAME, SITE_URL } from './env';

const UUID_RE =
  /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/i;

/**
 * متن → قطعه‌ی امن برای URL. حروف فارسی/عربی حفظ می‌شوند چون گوگل
 * URL یونیکد را درست ایندکس می‌کند و برای کاربر فارسی خواناتر است.
 */
export function slugify(input: string): string {
  return (input || '')
    .trim()
    .toLowerCase()
    .replace(/[‌‏‎]/g, '-')      // نیم‌فاصله و کاراکترهای جهت
    .replace(/[^\p{L}\p{N}]+/gu, '-')            // هرچه حرف و عدد نیست
    .replace(/^-+|-+$/g, '')
    .slice(0, 60)
    .replace(/-+$/g, '');
}

/**
 * URL خوانا از عنوان + شناسه: «نام-آهنگ--<uuid>».
 * جداکننده دو خط تیره است تا با خط تیره‌های داخل slug اشتباه نشود.
 */
export function buildSlug(title: string, id: string): string {
  const slug = slugify(title);
  return slug ? `${slug}--${id}` : id;
}

/** از پارامتر مسیر، شناسه‌ی واقعی را بیرون می‌کشد. */
export function extractId(param: string): string | null {
  const decoded = decodeURIComponent(param || '');
  const match = decoded.match(UUID_RE);
  return match ? match[0] : null;
}

/** آیا پارامتر مسیر دقیقاً همان شکل canonical است؟ (برای ریدایرکت ۳۰۱) */
export function isCanonicalSlug(param: string, title: string, id: string): boolean {
  return decodeURIComponent(param || '') === buildSlug(title, id);
}

// ---------------------------------------------------------------------------
// ساخت مسیرها — تنها منبع حقیقت برای لینک‌های داخلی و sitemap
// ---------------------------------------------------------------------------

export const routes = {
  home: () => '/',
  track: (title: string, id: string) => `/track/${buildSlug(title, id)}`,
  artist: (username: string) => `/artist/${encodeURIComponent(username)}`,
  genre: (genre: string) => `/genre/${encodeURIComponent(slugify(genre))}`,
  playlist: (title: string, id: string) => `/playlist/${buildSlug(title, id)}`,
  search: (query?: string) =>
    query ? `/search?q=${encodeURIComponent(query)}` : '/search',
  trending: () => '/trending',
  newest: () => '/new',
};

/** مسیر نسبی → URL مطلق روی دامنه‌ی سایت (برای canonical و OpenGraph) */
export const absoluteUrl = (path: string) =>
  `${SITE_URL}${path.startsWith('/') ? path : `/${path}`}`;

/**
 * مسیر رسانه در دیتابیس نسبی است (`uploads/covers/x.jpg`).
 * این تابع آن را به URL مطلق تبدیل می‌کند و مقادیر مطلق را دست‌نخورده می‌گذارد.
 */
export function mediaUrl(path: string | null | undefined): string | null {
  if (!path) return null;
  if (/^https?:\/\//i.test(path)) return path;
  return `${MEDIA_URL}/${path.replace(/^\/+/, '')}`;
}

// ---------------------------------------------------------------------------
// متن متادیتا
// ---------------------------------------------------------------------------

/** توضیحات متا: تک‌خطی و بریده در مرز کلمه (حدود ۱۶۰ کاراکتر). */
export function metaDescription(text: string, max = 160): string {
  const flat = (text || '').replace(/\s+/g, ' ').trim();
  if (flat.length <= max) return flat;
  const cut = flat.slice(0, max);
  const lastSpace = cut.lastIndexOf(' ');
  return `${(lastSpace > max * 0.6 ? cut.slice(0, lastSpace) : cut).trim()}…`;
}

/** عنوان صفحه با پسوند نام سایت */
export const pageTitle = (title: string) => `${title} | ${SITE_NAME}`;

/**
 * تنظیمات محیطی — یک‌جا و اعتبارسنجی‌شده.
 * همه‌ی مقادیر بدون اسلش انتهایی نرمال می‌شوند تا ساخت URL قابل‌پیش‌بینی بماند.
 */
const trim = (value: string) => value.replace(/\/+$/, '');

export const SITE_URL = trim(
  process.env.NEXT_PUBLIC_SITE_URL || 'http://localhost:3001',
);

/**
 * آدرس API برای درخواست‌های سمت سرور.
 * روی پروداکشن به 127.0.0.1:3000 وصل می‌شویم تا درخواست از CDN و
 * شبکه‌ی بیرونی رد نشود — هم سریع‌تر است هم به بار CDN اضافه نمی‌کند.
 * فقط در کد سرور استفاده شود؛ این متغیر NEXT_PUBLIC_ نیست و به مرورگر نمی‌رود.
 */
export const API_URL = trim(
  process.env.API_INTERNAL_URL ||
    process.env.NEXT_PUBLIC_API_URL ||
    'http://localhost:3000/api/v1',
);

export const MEDIA_URL = trim(
  process.env.NEXT_PUBLIC_MEDIA_URL || 'http://localhost:3000',
);

export const GOOGLE_SITE_VERIFICATION =
  process.env.NEXT_PUBLIC_GOOGLE_SITE_VERIFICATION || '';

/** مدت اعتبار کش صفحات عمومی (ISR) بر حسب ثانیه */
export const REVALIDATE = Number(process.env.REVALIDATE_SECONDS || 300);

export const SITE_NAME = 'فول موزیک';
export const SITE_TAGLINE = 'شبکه‌ی اجتماعی موسیقی';
export const SITE_DESCRIPTION =
  'فول موزیک؛ پلتفرم اشتراک‌گذاری موسیقی مستقل. آهنگ‌های تازه را بشنوید، هنرمندان را دنبال کنید و آثار خودتان را منتشر کنید.';

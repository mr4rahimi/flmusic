import { APP_DOWNLOAD_URL, APP_NAME, APP_TAGLINE, SITE_NAME } from '@/lib/env';

/**
 * معرفی اپلیکیشن فندوق در صفحه‌ی اصلی.
 *
 * اف ال موزیک فقط ویترین عمومی و قابل ایندکس محتواست؛ کارهای تعاملی
 * (لایک، پلی‌لیست شخصی، آپلود، دنبال‌کردن، کامنت) در اپ موبایل انجام می‌شود.
 * فهرست امکانات از روی خود اپ نوشته شده — apps/mobile/lib/features/.
 */
const FEATURES = [
  {
    title: 'انتشار و آپلود آهنگ',
    body: `آهنگ خودتان را با کاور، نام خواننده و سبک آپلود کنید؛ همان لحظه در ${SITE_NAME} هم صفحه‌ی اختصاصی می‌گیرد.`,
  },
  {
    title: 'پلی‌لیست شخصی',
    body: 'هر تعداد پلی‌لیست بسازید، آهنگ‌ها را داخلشان مرتب کنید و همه‌جا در دسترس داشته باشید.',
  },
  {
    title: 'لایک و ذخیره',
    body: 'آهنگ‌های مورد علاقه‌تان را لایک کنید تا همیشه یک‌جا جمع باشند.',
  },
  {
    title: 'دنبال‌کردن و فید اختصاصی',
    body: 'کاربران و خواننده‌های دلخواهتان را دنبال کنید و فید شخصی‌سازی‌شده‌ی خودتان را داشته باشید.',
  },
  {
    title: 'نظر و بازنشر',
    body: 'زیر هر آهنگ نظر بگذارید، بازنشرش کنید و در گفت‌وگوی شنونده‌ها شریک شوید.',
  },
  {
    title: 'پخش‌کننده‌ی کامل',
    body: 'پخش پیوسته، کنترل از روی صفحه‌ی قفل و اعلان‌های لحظه‌ای برای فعالیت‌های جدید.',
  },
];

export function AppPromo() {
  return (
    <section
      aria-labelledby="app-promo-title"
      className="mb-12 rounded-2xl border border-neutral-800 bg-neutral-900/40 p-6 sm:p-8"
    >
      <h2 id="app-promo-title" className="text-lg font-semibold sm:text-xl">
        اپلیکیشن {APP_NAME} — {APP_TAGLINE}
      </h2>

      <p className="mt-3 max-w-3xl text-sm leading-7 text-neutral-300">
        آهنگ‌هایی که در {SITE_NAME} می‌شنوید، در اپلیکیشن {APP_NAME} منتشر شده‌اند؛
        یک شبکه‌ی اجتماعی تخصصی موسیقی. برای ساخت <strong>پلی‌لیست شخصی</strong>،{' '}
        <strong>لایک‌کردن</strong> آهنگ‌ها، <strong>آپلود آهنگ</strong> خودتان،
        دنبال‌کردن کاربران و گذاشتن نظر، اپ {APP_NAME} را نصب کنید.
      </p>

      <ul className="mt-6 grid gap-x-8 gap-y-5 sm:grid-cols-2 lg:grid-cols-3">
        {FEATURES.map((feature) => (
          <li key={feature.title}>
            <h3 className="text-sm font-medium text-emerald-400">{feature.title}</h3>
            <p className="mt-1 text-xs leading-6 text-neutral-400">{feature.body}</p>
          </li>
        ))}
      </ul>

      {APP_DOWNLOAD_URL && (
        <a
          href={APP_DOWNLOAD_URL}
          className="mt-7 inline-flex items-center gap-2 rounded-full bg-emerald-500 px-5 py-2.5 text-sm font-medium text-black transition hover:bg-emerald-400"
        >
          دانلود اپلیکیشن {APP_NAME}
        </a>
      )}
    </section>
  );
}

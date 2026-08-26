import Link from 'next/link';
import type { Metadata } from 'next';

import { routes } from '@/lib/seo';

export const metadata: Metadata = {
  title: 'صفحه پیدا نشد',
  robots: { index: false, follow: true },
};

export default function NotFound() {
  return (
    <div className="py-20 text-center">
      <p className="text-5xl font-bold text-emerald-400">۴۰۴</p>
      <h1 className="mt-4 text-xl font-semibold">این صفحه پیدا نشد</h1>
      <p className="mt-2 text-sm text-neutral-400">
        شاید آهنگ حذف شده یا آدرس را اشتباه وارد کرده‌اید.
      </p>
      <div className="mt-6 flex justify-center gap-3 text-sm">
        <Link
          href={routes.home()}
          className="rounded-full bg-emerald-500 px-5 py-2 text-black hover:bg-emerald-400"
        >
          صفحه‌ی اصلی
        </Link>
        <Link
          href={routes.trending()}
          className="rounded-full border border-neutral-700 px-5 py-2 hover:border-neutral-500"
        >
          داغ‌ترین آهنگ‌ها
        </Link>
      </div>
    </div>
  );
}

import Link from 'next/link';
import { SITE_NAME } from '@/lib/env';
import { toFaDigits } from '@/lib/format';
import { routes } from '@/lib/seo';

export function SiteFooter() {
  return (
    <footer className="mt-16 border-t border-neutral-800 py-8 text-sm text-neutral-400">
      <div className="mx-auto flex max-w-6xl flex-col gap-4 px-4 sm:flex-row sm:items-center sm:justify-between">
        <p>
          © {toFaDigits(new Date().getFullYear())} {SITE_NAME}
        </p>
        <nav aria-label="ناوبری پاورقی" className="flex gap-4">
          <Link href={routes.trending()} className="hover:text-white">
            داغ‌ترین‌ها
          </Link>
          <Link href={routes.newest()} className="hover:text-white">
            جدیدترین‌ها
          </Link>
          <Link href={routes.search()} className="hover:text-white">
            جستجو
          </Link>
        </nav>
      </div>
    </footer>
  );
}

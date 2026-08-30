import Link from 'next/link';
import { Suspense } from 'react';
import { SearchBox } from './SearchBox';
import { SITE_NAME } from '@/lib/env';
import { routes } from '@/lib/seo';

const NAV_LINKS = [
  { href: routes.trending(), label: 'داغ‌ترین‌ها' },
  { href: routes.newest(), label: 'جدیدترین‌ها' },
  { href: routes.singers(), label: 'خواننده‌ها' },
  { href: routes.styles(), label: 'سبک‌ها' },
];

export function SiteHeader() {
  return (
    <header className="sticky top-0 z-40 border-b border-neutral-800 bg-neutral-950/90 backdrop-blur">
      <div className="mx-auto flex max-w-6xl items-center gap-4 px-4 py-3">
        <Link href={routes.home()} className="shrink-0 text-lg font-bold text-emerald-400">
          {SITE_NAME}
        </Link>

        <nav aria-label="ناوبری اصلی" className="hidden gap-4 text-sm text-neutral-300 sm:flex">
          {NAV_LINKS.map((link) => (
            <Link key={link.href} href={link.href} className="hover:text-white">
              {link.label}
            </Link>
          ))}
        </nav>

        <div className="ms-auto w-full max-w-xs">
          {/* useSearchParams نیاز به Suspense دارد تا صفحات استاتیک بمانند */}
          <Suspense fallback={<div className="h-9 rounded-full bg-neutral-900" />}>
            <SearchBox />
          </Suspense>
        </div>
      </div>
    </header>
  );
}

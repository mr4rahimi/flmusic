import type { Metadata } from 'next';
import Link from 'next/link';

import { Breadcrumbs } from '@/components/Breadcrumbs';
import { JsonLd } from '@/components/JsonLd';
import { getGenres } from '@/lib/api';
import { SITE_NAME } from '@/lib/env';
import { toFaDigits } from '@/lib/format';
import { breadcrumbSchema, graph } from '@/lib/jsonld';
import { absoluteUrl, routes } from '@/lib/seo';

export const revalidate = 3600;

const TITLE = 'سبک‌های موسیقی';
const DESCRIPTION = `فهرست سبک‌های موسیقی در ${SITE_NAME}؛ از هر سبک، آهنگ‌های منتشرشده را ببینید و آنلاین بشنوید.`;

export const metadata: Metadata = {
  title: TITLE,
  description: DESCRIPTION,
  alternates: { canonical: '/genre' },
  openGraph: { title: TITLE, description: DESCRIPTION, url: absoluteUrl('/genre') },
};

export default async function GenreIndexPage() {
  const genres = await getGenres();
  const crumbs = [
    { name: 'خانه', path: routes.home() },
    { name: TITLE, path: '/genre' },
  ];

  return (
    <>
      <JsonLd data={graph(breadcrumbSchema(crumbs))} />
      <Breadcrumbs items={crumbs} />

      <h1 className="text-2xl font-bold">{TITLE}</h1>
      <p className="mt-2 mb-8 max-w-2xl text-sm leading-7 text-neutral-400">
        {DESCRIPTION}
      </p>

      {genres.length === 0 ? (
        <p className="text-sm text-neutral-500">هنوز سبکی ثبت نشده است.</p>
      ) : (
        <ul className="flex flex-wrap gap-3">
          {genres.map(({ genre, count }) => (
            <li key={genre}>
              <Link
                href={routes.genre(genre)}
                className="inline-flex items-center gap-2 rounded-full border border-neutral-800 px-4 py-2 text-sm transition hover:border-emerald-500 hover:text-emerald-400"
              >
                {genre}
                <span className="tabular-nums text-xs text-neutral-500">
                  {toFaDigits(count)}
                </span>
              </Link>
            </li>
          ))}
        </ul>
      )}
    </>
  );
}

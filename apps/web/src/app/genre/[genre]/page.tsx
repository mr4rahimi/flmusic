import type { Metadata } from 'next';
import { notFound } from 'next/navigation';

import { Breadcrumbs } from '@/components/Breadcrumbs';
import { JsonLd } from '@/components/JsonLd';
import { TrackGrid } from '@/components/TrackGrid';
import { getGenres, getTracksByGenre } from '@/lib/api';
import { SITE_NAME } from '@/lib/env';
import { formatCount } from '@/lib/format';
import { breadcrumbSchema, collectionSchema, graph } from '@/lib/jsonld';
import { absoluteUrl, metaDescription, routes, slugify } from '@/lib/seo';

export const revalidate = 600;

type PageProps = { params: Promise<{ genre: string }> };

/**
 * پارامتر مسیر، نسخه‌ی slug شده‌ی نام سبک است.
 * نام اصلی را از فهرست سبک‌ها پیدا می‌کنیم تا عنوان صفحه درست نمایش داده شود.
 */
async function resolveGenre(param: string): Promise<string | null> {
  const slug = decodeURIComponent(param);
  const genres = await getGenres();
  const match = genres.find((item) => slugify(item.genre) === slug);
  return match?.genre ?? null;
}

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { genre: param } = await params;
  const genre = await resolveGenre(param);

  if (!genre) {
    return { title: 'سبک پیدا نشد', robots: { index: false, follow: false } };
  }

  const title = `آهنگ‌های سبک ${genre}`;
  const description = metaDescription(
    `مجموعه آهنگ‌های سبک ${genre} در ${SITE_NAME}. جدیدترین و پرشنیده‌ترین آثار این سبک را آنلاین گوش کنید.`,
  );

  return {
    title,
    description,
    alternates: { canonical: routes.genre(genre) },
    openGraph: {
      title,
      description,
      url: absoluteUrl(routes.genre(genre)),
      siteName: SITE_NAME,
      locale: 'fa_IR',
    },
  };
}

/** سبک‌های موجود از قبل ساخته می‌شوند تا اولین بازدید هم سریع باشد. */
export async function generateStaticParams() {
  const genres = await getGenres();
  return genres.map(({ genre }) => ({ genre: slugify(genre) }));
}

export default async function GenrePage({ params }: PageProps) {
  const { genre: param } = await params;
  const genre = await resolveGenre(param);
  if (!genre) notFound();

  const tracks = await getTracksByGenre(genre);
  const title = `آهنگ‌های سبک ${genre}`;
  const description = `مجموعه آهنگ‌های سبک ${genre} در ${SITE_NAME}.`;

  const crumbs = [
    { name: 'خانه', path: routes.home() },
    { name: 'سبک‌ها', path: '/genre' },
    { name: genre, path: routes.genre(genre) },
  ];

  return (
    <>
      <JsonLd
        data={graph(
          collectionSchema(title, description, routes.genre(genre), tracks),
          breadcrumbSchema(crumbs),
        )}
      />
      <Breadcrumbs items={crumbs} />

      <h1 className="text-2xl font-bold">{title}</h1>
      <p className="mt-2 mb-8 max-w-2xl text-sm leading-7 text-neutral-400">
        {formatCount(tracks.length)} آهنگ در این سبک منتشر شده است. تازه‌ترین و
        پرشنیده‌ترین آثار سبک {genre} را اینجا بشنوید.
      </p>

      <TrackGrid
        tracks={tracks}
        priorityCount={5}
        emptyMessage={`هنوز آهنگی با سبک ${genre} منتشر نشده است.`}
      />
    </>
  );
}

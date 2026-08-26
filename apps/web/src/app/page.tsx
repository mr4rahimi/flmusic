import type { Metadata } from 'next';
import Link from 'next/link';

import { JsonLd } from '@/components/JsonLd';
import { TrackGrid } from '@/components/TrackGrid';
import { getNewTracks, getTrendingTracks } from '@/lib/api';
import { SITE_DESCRIPTION, SITE_NAME, SITE_TAGLINE } from '@/lib/env';
import { collectionSchema, graph } from '@/lib/jsonld';
import { routes } from '@/lib/seo';

// Next مقدار revalidate را باید به‌صورت ثابت ببیند (نه متغیر محیطی).
export const revalidate = 300;

export const metadata: Metadata = {
  title: `${SITE_NAME} | ${SITE_TAGLINE}`,
  description: SITE_DESCRIPTION,
  alternates: { canonical: '/' },
};

export default async function HomePage() {
  // موازی، نه پشت‌سرهم — TTFB نصف می‌شود
  const [trending, newest] = await Promise.all([
    getTrendingTracks(1, 10),
    getNewTracks(1, 10),
  ]);

  return (
    <>
      <JsonLd
        data={graph(
          collectionSchema(
            `${SITE_NAME} — ${SITE_TAGLINE}`,
            SITE_DESCRIPTION,
            '/',
            [...trending, ...newest],
          ),
        )}
      />

      {/* تنها h1 صفحه؛ متن واقعی و قابل ایندکس، نه فقط تصویر */}
      <section className="mb-10">
        <h1 className="text-2xl font-bold sm:text-3xl">
          {SITE_NAME} — {SITE_TAGLINE}
        </h1>
        <p className="mt-2 max-w-2xl text-sm leading-7 text-neutral-400">
          {SITE_DESCRIPTION}
        </p>
      </section>

      <Section
        title="داغ‌ترین آهنگ‌ها"
        description="پرشنیده‌ترین آهنگ‌های این روزهای فول موزیک."
        href={routes.trending()}
        tracks={trending}
        priorityCount={5}
      />

      <Section
        title="جدیدترین آهنگ‌ها"
        description="تازه‌ترین آثاری که هنرمندان منتشر کرده‌اند."
        href={routes.newest()}
        tracks={newest}
      />
    </>
  );
}

function Section({
  title,
  description,
  href,
  tracks,
  priorityCount = 0,
}: {
  title: string;
  description: string;
  href: string;
  tracks: Awaited<ReturnType<typeof getTrendingTracks>>;
  priorityCount?: number;
}) {
  return (
    <section className="mb-12">
      <div className="mb-4 flex items-baseline justify-between gap-4">
        <div>
          <h2 className="text-lg font-semibold">{title}</h2>
          <p className="text-xs text-neutral-500">{description}</p>
        </div>
        <Link href={href} className="shrink-0 text-sm text-emerald-400 hover:underline">
          مشاهده‌ی همه
        </Link>
      </div>
      <TrackGrid tracks={tracks} priorityCount={priorityCount} />
    </section>
  );
}

import type { Metadata } from 'next';
import Link from 'next/link';

import { AppPromo } from '@/components/AppPromo';
import { FacetList } from '@/components/FacetList';
import { JsonLd } from '@/components/JsonLd';
import { TrackGrid } from '@/components/TrackGrid';
import { getNewTracks, getSingers, getStyles, getTrendingTracks } from '@/lib/api';
import { APP_NAME, SITE_DESCRIPTION, SITE_NAME, SITE_TAGLINE } from '@/lib/env';
import { collectionSchema, graph } from '@/lib/jsonld';
import { routes } from '@/lib/seo';

// Next مقدار revalidate را باید به‌صورت ثابت ببیند (نه متغیر محیطی).
export const revalidate = 300;

export const metadata: Metadata = {
  title: `${SITE_NAME} | ${SITE_TAGLINE}`,
  description: SITE_DESCRIPTION,
  alternates: { canonical: '/' },
};

/** چند تا از خواننده‌ها و سبک‌ها در صفحه‌ی اصلی لینک شوند (لینک‌سازی داخلی) */
const TOP_SINGERS = 18;
const TOP_STYLES = 14;

export default async function HomePage() {
  // موازی، نه پشت‌سرهم — TTFB نصف می‌شود
  const [trending, newest, singers, styles] = await Promise.all([
    getTrendingTracks(1, 10),
    getNewTracks(1, 10),
    getSingers(),
    getStyles(),
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
        description={`پرشنیده‌ترین آهنگ‌های این روزهای ${SITE_NAME}.`}
        href={routes.trending()}
        tracks={trending}
        priorityCount={5}
      />

      <Section
        title="جدیدترین آهنگ‌ها"
        description={`تازه‌ترین آثاری که کاربران ${APP_NAME} منتشر کرده‌اند.`}
        href={routes.newest()}
        tracks={newest}
      />

      {/* معرفی اپ — پیش از فهرست‌های دسته‌بندی، جایی که کاربر بعد از
          شنیدن چند آهنگ آماده‌ی نصب است */}
      <AppPromo />

      {singers.length > 0 && (
        <FacetSection
          title="خواننده‌های محبوب"
          description="آهنگ‌ها را بر اساس خواننده مرور کنید."
          href={routes.singers()}
        >
          <FacetList
            items={singers.slice(0, TOP_SINGERS)}
            href={routes.singer}
            emptyMessage=""
          />
        </FacetSection>
      )}

      {styles.length > 0 && (
        <FacetSection
          title="سبک‌های موسیقی"
          description="عاشقانه، شاد، سنتی و… — سبک دلخواهتان را انتخاب کنید."
          href={routes.styles()}
        >
          <FacetList
            items={styles.slice(0, TOP_STYLES)}
            href={routes.style}
            emptyMessage=""
          />
        </FacetSection>
      )}
    </>
  );
}

function SectionHeader({
  title,
  description,
  href,
}: {
  title: string;
  description: string;
  href: string;
}) {
  return (
    <div className="mb-4 flex items-baseline justify-between gap-4">
      <div>
        <h2 className="text-lg font-semibold">{title}</h2>
        <p className="text-xs text-neutral-500">{description}</p>
      </div>
      <Link href={href} className="shrink-0 text-sm text-emerald-400 hover:underline">
        مشاهده‌ی همه
      </Link>
    </div>
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
      <SectionHeader title={title} description={description} href={href} />
      <TrackGrid tracks={tracks} priorityCount={priorityCount} />
    </section>
  );
}

function FacetSection({
  title,
  description,
  href,
  children,
}: {
  title: string;
  description: string;
  href: string;
  children: React.ReactNode;
}) {
  return (
    <section className="mb-12">
      <SectionHeader title={title} description={description} href={href} />
      {children}
    </section>
  );
}

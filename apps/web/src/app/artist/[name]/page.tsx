import type { Metadata } from 'next';
import { notFound, permanentRedirect } from 'next/navigation';

import { Breadcrumbs } from '@/components/Breadcrumbs';
import { JsonLd } from '@/components/JsonLd';
import { TrackGrid } from '@/components/TrackGrid';
import { StyleChips } from '@/components/StyleChips';
import { getProfile, getSingers, getTracksBySinger } from '@/lib/api';
import { SITE_NAME } from '@/lib/env';
import { formatCount } from '@/lib/format';
import { breadcrumbSchema, collectionSchema, graph, singerSchema } from '@/lib/jsonld';
import { absoluteUrl, metaDescription, routes, slugify } from '@/lib/seo';
import { stylesOf } from '@/lib/types';

export const revalidate = 600;

type PageProps = { params: Promise<{ name: string }> };

/**
 * پارامتر مسیر، نسخه‌ی slug شده‌ی نام خواننده است.
 * نام اصلی را از فهرست خواننده‌ها پیدا می‌کنیم تا عنوان صفحه درست باشد.
 */
async function resolveSinger(param: string): Promise<string | null> {
  const slug = decodeURIComponent(param);
  const singers = await getSingers();
  return singers.find((item) => slugify(item.name) === slug)?.name ?? null;
}

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { name: param } = await params;
  const singer = await resolveSinger(param);

  if (!singer) {
    return { title: 'خواننده پیدا نشد', robots: { index: false, follow: false } };
  }

  const title = `آهنگ‌های ${singer}`;
  const description = metaDescription(
    `همه‌ی آهنگ‌های ${singer} در ${SITE_NAME}؛ جدیدترین و پرشنیده‌ترین آثار ${singer} را آنلاین بشنوید و دانلود کنید.`,
  );

  return {
    title,
    description,
    keywords: [singer, `آهنگ ${singer}`, `دانلود آهنگ ${singer}`, `آهنگ جدید ${singer}`],
    alternates: { canonical: routes.singer(singer) },
    openGraph: {
      title,
      description,
      url: absoluteUrl(routes.singer(singer)),
      siteName: SITE_NAME,
      locale: 'fa_IR',
    },
  };
}

/** صفحه‌ی خواننده‌ها از قبل ساخته می‌شود تا اولین بازدید هم سریع باشد. */
export async function generateStaticParams() {
  const singers = await getSingers();
  return singers.map(({ name }) => ({ name: slugify(name) }));
}

export default async function SingerPage({ params }: PageProps) {
  const { name: param } = await params;
  const slug = decodeURIComponent(param);
  const singer = await resolveSinger(param);

  if (!singer) {
    // پیش از این `/artist/[username]` صفحه‌ی پروفایل کاربر بود.
    // اگر آدرس قدیمی خزیده شده، به مسیر جدیدش می‌فرستیم نه ۴۰۴.
    const profile = await getProfile(slug);
    if (profile) permanentRedirect(routes.user(profile.username));
    notFound();
  }

  const tracks = await getTracksBySinger(singer);
  const title = `آهنگ‌های ${singer}`;
  const description = `مجموعه آهنگ‌های ${singer} در ${SITE_NAME}.`;

  // سبک‌های پرتکرار این خواننده — لینک داخلی به صفحات سبک
  const styles = [...new Set(tracks.flatMap(stylesOf))].slice(0, 12);

  const crumbs = [
    { name: 'خانه', path: routes.home() },
    { name: 'خواننده‌ها', path: routes.singers() },
    { name: singer, path: routes.singer(singer) },
  ];

  return (
    <>
      <JsonLd
        data={graph(
          singerSchema(singer, tracks),
          collectionSchema(title, description, routes.singer(singer), tracks),
          breadcrumbSchema(crumbs),
        )}
      />
      <Breadcrumbs items={crumbs} />

      <h1 className="text-2xl font-bold">{title}</h1>
      <p className="mt-2 max-w-2xl text-sm leading-7 text-neutral-400">
        {formatCount(tracks.length)} آهنگ از {singer} در {SITE_NAME} منتشر شده است.
        تازه‌ترین و پرشنیده‌ترین آثار او را اینجا بشنوید.
      </p>

      {styles.length > 0 && (
        <div className="mt-4">
          <StyleChips styles={styles} label={`سبک‌های ${singer}`} />
        </div>
      )}

      <div className="mt-8">
        <TrackGrid
          tracks={tracks}
          priorityCount={5}
          emptyMessage={`هنوز آهنگی از ${singer} منتشر نشده است.`}
        />
      </div>
    </>
  );
}

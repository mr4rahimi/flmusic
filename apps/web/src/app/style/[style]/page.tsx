import type { Metadata } from 'next';
import { notFound } from 'next/navigation';

import { Breadcrumbs } from '@/components/Breadcrumbs';
import { JsonLd } from '@/components/JsonLd';
import { TrackGrid } from '@/components/TrackGrid';
import { getStyles, getTracksByStyle } from '@/lib/api';
import { SITE_NAME } from '@/lib/env';
import { formatCount } from '@/lib/format';
import { breadcrumbSchema, collectionSchema, graph } from '@/lib/jsonld';
import { absoluteUrl, metaDescription, routes, slugify } from '@/lib/seo';

export const revalidate = 600;

type PageProps = { params: Promise<{ style: string }> };

/** پارامتر مسیر، نسخه‌ی slug شده‌ی نام سبک است. */
async function resolveStyle(param: string): Promise<string | null> {
  const slug = decodeURIComponent(param);
  const styles = await getStyles();
  return styles.find((item) => slugify(item.name) === slug)?.name ?? null;
}

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { style: param } = await params;
  const style = await resolveStyle(param);

  if (!style) {
    return { title: 'سبک پیدا نشد', robots: { index: false, follow: false } };
  }

  const title = `آهنگ‌های سبک ${style}`;
  const description = metaDescription(
    `مجموعه آهنگ‌های سبک ${style} در ${SITE_NAME}. جدیدترین و پرشنیده‌ترین آثار این سبک را آنلاین گوش کنید.`,
  );

  return {
    title,
    description,
    keywords: [style, `آهنگ ${style}`, `آهنگ‌های سبک ${style}`],
    alternates: { canonical: routes.style(style) },
    openGraph: {
      title,
      description,
      url: absoluteUrl(routes.style(style)),
      siteName: SITE_NAME,
      locale: 'fa_IR',
    },
  };
}

export async function generateStaticParams() {
  const styles = await getStyles();
  return styles.map(({ name }) => ({ style: slugify(name) }));
}

export default async function StylePage({ params }: PageProps) {
  const { style: param } = await params;
  const style = await resolveStyle(param);
  if (!style) notFound();

  const tracks = await getTracksByStyle(style);
  const title = `آهنگ‌های سبک ${style}`;
  const description = `مجموعه آهنگ‌های سبک ${style} در ${SITE_NAME}.`;

  const crumbs = [
    { name: 'خانه', path: routes.home() },
    { name: 'سبک‌ها', path: routes.styles() },
    { name: style, path: routes.style(style) },
  ];

  return (
    <>
      <JsonLd
        data={graph(
          collectionSchema(title, description, routes.style(style), tracks),
          breadcrumbSchema(crumbs),
        )}
      />
      <Breadcrumbs items={crumbs} />

      <h1 className="text-2xl font-bold">{title}</h1>
      <p className="mt-2 mb-8 max-w-2xl text-sm leading-7 text-neutral-400">
        {formatCount(tracks.length)} آهنگ در سبک {style} منتشر شده است. تازه‌ترین و
        پرشنیده‌ترین آثار این سبک را اینجا بشنوید.
      </p>

      <TrackGrid
        tracks={tracks}
        priorityCount={5}
        emptyMessage={`هنوز آهنگی با سبک ${style} منتشر نشده است.`}
      />
    </>
  );
}

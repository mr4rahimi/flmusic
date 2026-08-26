import type { Metadata } from 'next';

import { Breadcrumbs } from '@/components/Breadcrumbs';
import { JsonLd } from '@/components/JsonLd';
import { TrackGrid } from '@/components/TrackGrid';
import { getTrendingTracks } from '@/lib/api';
import { SITE_NAME } from '@/lib/env';
import { breadcrumbSchema, collectionSchema, graph } from '@/lib/jsonld';
import { routes } from '@/lib/seo';

export const revalidate = 300;

const TITLE = 'داغ‌ترین آهنگ‌ها';
const DESCRIPTION = `پرشنیده‌ترین آهنگ‌های ${SITE_NAME}؛ فهرستی از آثاری که این روزها بیشترین پخش را داشته‌اند.`;

export const metadata: Metadata = {
  title: TITLE,
  description: DESCRIPTION,
  alternates: { canonical: routes.trending() },
  openGraph: { title: TITLE, description: DESCRIPTION, url: routes.trending() },
};

export default async function TrendingPage() {
  const tracks = await getTrendingTracks(1, 48);
  const crumbs = [
    { name: 'خانه', path: routes.home() },
    { name: TITLE, path: routes.trending() },
  ];

  return (
    <>
      <JsonLd
        data={graph(
          collectionSchema(TITLE, DESCRIPTION, routes.trending(), tracks),
          breadcrumbSchema(crumbs),
        )}
      />
      <Breadcrumbs items={crumbs} />
      <h1 className="text-2xl font-bold">{TITLE}</h1>
      <p className="mt-2 mb-8 max-w-2xl text-sm leading-7 text-neutral-400">
        {DESCRIPTION}
      </p>
      <TrackGrid tracks={tracks} priorityCount={5} />
    </>
  );
}

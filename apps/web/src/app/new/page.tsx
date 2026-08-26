import type { Metadata } from 'next';

import { Breadcrumbs } from '@/components/Breadcrumbs';
import { JsonLd } from '@/components/JsonLd';
import { TrackGrid } from '@/components/TrackGrid';
import { getNewTracks } from '@/lib/api';
import { SITE_NAME } from '@/lib/env';
import { breadcrumbSchema, collectionSchema, graph } from '@/lib/jsonld';
import { routes } from '@/lib/seo';

// فهرست جدیدترین‌ها سریع‌تر کهنه می‌شود، پس کش کوتاه‌تر
export const revalidate = 120;

const TITLE = 'جدیدترین آهنگ‌ها';
const DESCRIPTION = `تازه‌ترین آهنگ‌های منتشرشده در ${SITE_NAME}؛ هر روز به‌روز می‌شود.`;

export const metadata: Metadata = {
  title: TITLE,
  description: DESCRIPTION,
  alternates: { canonical: routes.newest() },
  openGraph: { title: TITLE, description: DESCRIPTION, url: routes.newest() },
};

export default async function NewPage() {
  const tracks = await getNewTracks(1, 48);
  const crumbs = [
    { name: 'خانه', path: routes.home() },
    { name: TITLE, path: routes.newest() },
  ];

  return (
    <>
      <JsonLd
        data={graph(
          collectionSchema(TITLE, DESCRIPTION, routes.newest(), tracks),
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

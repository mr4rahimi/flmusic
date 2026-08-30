import type { Metadata } from 'next';

import { Breadcrumbs } from '@/components/Breadcrumbs';
import { FacetList } from '@/components/FacetList';
import { JsonLd } from '@/components/JsonLd';
import { getSingers } from '@/lib/api';
import { SITE_NAME } from '@/lib/env';
import { breadcrumbSchema, graph } from '@/lib/jsonld';
import { absoluteUrl, routes } from '@/lib/seo';

export const revalidate = 3600;

const TITLE = 'خواننده‌ها';
const DESCRIPTION = `فهرست خواننده‌های ${SITE_NAME}؛ از هر خواننده، همه‌ی آهنگ‌های منتشرشده را ببینید، آنلاین بشنوید و دانلود کنید.`;

export const metadata: Metadata = {
  title: TITLE,
  description: DESCRIPTION,
  alternates: { canonical: routes.singers() },
  openGraph: {
    title: TITLE,
    description: DESCRIPTION,
    url: absoluteUrl(routes.singers()),
  },
};

export default async function SingersPage() {
  const singers = await getSingers();
  const crumbs = [
    { name: 'خانه', path: routes.home() },
    { name: TITLE, path: routes.singers() },
  ];

  return (
    <>
      <JsonLd data={graph(breadcrumbSchema(crumbs))} />
      <Breadcrumbs items={crumbs} />

      <h1 className="text-2xl font-bold">{TITLE}</h1>
      <p className="mt-2 mb-8 max-w-2xl text-sm leading-7 text-neutral-400">
        {DESCRIPTION}
      </p>

      <FacetList
        items={singers}
        href={routes.singer}
        emptyMessage="هنوز خواننده‌ای ثبت نشده است."
      />
    </>
  );
}

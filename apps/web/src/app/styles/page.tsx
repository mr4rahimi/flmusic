import type { Metadata } from 'next';

import { Breadcrumbs } from '@/components/Breadcrumbs';
import { FacetList } from '@/components/FacetList';
import { JsonLd } from '@/components/JsonLd';
import { getStyles } from '@/lib/api';
import { SITE_NAME } from '@/lib/env';
import { breadcrumbSchema, graph } from '@/lib/jsonld';
import { absoluteUrl, routes } from '@/lib/seo';

export const revalidate = 3600;

const TITLE = 'سبک‌های موسیقی';
const DESCRIPTION = `فهرست سبک‌های موسیقی در ${SITE_NAME}؛ عاشقانه، شاد، سنتی و… . از هر سبک، آهنگ‌های منتشرشده را ببینید و آنلاین بشنوید.`;

export const metadata: Metadata = {
  title: TITLE,
  description: DESCRIPTION,
  alternates: { canonical: routes.styles() },
  openGraph: {
    title: TITLE,
    description: DESCRIPTION,
    url: absoluteUrl(routes.styles()),
  },
};

export default async function StylesPage() {
  const styles = await getStyles();
  const crumbs = [
    { name: 'خانه', path: routes.home() },
    { name: TITLE, path: routes.styles() },
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
        items={styles}
        href={routes.style}
        emptyMessage="هنوز سبکی ثبت نشده است."
      />
    </>
  );
}

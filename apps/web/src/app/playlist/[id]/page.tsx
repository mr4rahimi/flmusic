import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound, permanentRedirect } from 'next/navigation';

import { Breadcrumbs } from '@/components/Breadcrumbs';
import { JsonLd } from '@/components/JsonLd';
import { TrackGrid } from '@/components/TrackGrid';
import { getPlaylist } from '@/lib/api';
import { SITE_NAME } from '@/lib/env';
import { formatCount } from '@/lib/format';
import { breadcrumbSchema, graph, playlistSchema } from '@/lib/jsonld';
import {
  absoluteUrl,
  extractId,
  isCanonicalSlug,
  metaDescription,
  routes,
} from '@/lib/seo';

export const revalidate = 600;

type PageProps = { params: Promise<{ id: string }> };

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { id: param } = await params;
  const id = extractId(param);
  const playlist = id ? await getPlaylist(id) : null;

  if (!playlist) {
    return { title: 'پلی‌لیست پیدا نشد', robots: { index: false, follow: false } };
  }

  const count = playlist.tracks?.length ?? 0;
  const title = `پلی‌لیست ${playlist.title}`;
  const description = metaDescription(
    playlist.description ||
      `پلی‌لیست ${playlist.title} با ${formatCount(count)} آهنگ در ${SITE_NAME}.`,
  );

  return {
    title,
    description,
    alternates: { canonical: routes.playlist(playlist.title, playlist.id) },
    openGraph: {
      type: 'music.playlist',
      title,
      description,
      url: absoluteUrl(routes.playlist(playlist.title, playlist.id)),
      siteName: SITE_NAME,
      locale: 'fa_IR',
    },
  };
}

export default async function PlaylistPage({ params }: PageProps) {
  const { id: param } = await params;
  const id = extractId(param);
  const playlist = id ? await getPlaylist(id) : null;
  if (!playlist) notFound();

  if (!isCanonicalSlug(param, playlist.title, playlist.id)) {
    permanentRedirect(routes.playlist(playlist.title, playlist.id));
  }

  const tracks = playlist.tracks ?? [];
  const owner = playlist.user?.username;
  const crumbs = [
    { name: 'خانه', path: routes.home() },
    { name: playlist.title, path: routes.playlist(playlist.title, playlist.id) },
  ];

  return (
    <>
      <JsonLd data={graph(playlistSchema(playlist), breadcrumbSchema(crumbs))} />
      <Breadcrumbs items={crumbs} />

      <h1 className="text-2xl font-bold">{playlist.title}</h1>

      <p className="mt-2 text-sm text-neutral-400">
        {formatCount(tracks.length)} آهنگ
        {owner && (
          <>
            {' · ساخته‌ی '}
            <Link href={routes.user(owner)} className="text-emerald-400 hover:underline">
              {owner}
            </Link>
          </>
        )}
      </p>

      {playlist.description && (
        <p className="mt-3 max-w-2xl text-sm leading-7 text-neutral-300">
          {playlist.description}
        </p>
      )}

      <div className="mt-8">
        <TrackGrid
          tracks={tracks}
          priorityCount={5}
          emptyMessage="این پلی‌لیست هنوز آهنگی ندارد."
        />
      </div>
    </>
  );
}

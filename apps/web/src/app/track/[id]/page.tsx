import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound, permanentRedirect } from 'next/navigation';

import { Breadcrumbs } from '@/components/Breadcrumbs';
import { Cover } from '@/components/Cover';
import { JsonLd } from '@/components/JsonLd';
import { TrackGrid } from '@/components/TrackGrid';
import { PlayButton } from '@/components/player/PlayButton';
import { getTrack, getTracksByUsername } from '@/lib/api';
import { SITE_NAME } from '@/lib/env';
import { formatCount, formatDate, formatDuration } from '@/lib/format';
import { breadcrumbSchema, graph, trackSchema } from '@/lib/jsonld';
import {
  absoluteUrl,
  extractId,
  isCanonicalSlug,
  metaDescription,
  routes,
} from '@/lib/seo';
import type { Track } from '@/lib/types';

export const revalidate = 300;

type PageProps = { params: Promise<{ id: string }> };

/**
 * پارامتر مسیر می‌تواند «نام-آهنگ--<uuid>» یا فقط «<uuid>» باشد.
 * شناسه را بیرون می‌کشیم و آهنگ را می‌گیریم.
 */
async function loadTrack(param: string): Promise<Track | null> {
  const id = extractId(param);
  return id ? getTrack(id) : null;
}

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { id: param } = await params;
  const track = await loadTrack(param);

  if (!track) {
    return { title: 'آهنگ پیدا نشد', robots: { index: false, follow: false } };
  }

  const artist = track.user?.username;
  const title = artist ? `${track.title} — ${artist}` : track.title;
  const description = metaDescription(
    track.description ||
      `${track.title}${artist ? ` از ${artist}` : ''} را در ${SITE_NAME} آنلاین بشنوید و دانلود کنید.` +
        `${track.genre ? ` سبک: ${track.genre}.` : ''}`,
  );
  const canonical = routes.track(track.title, track.id);
  // تصویر ساخته‌شده توسط opengraph-image.tsx همین مسیر.
  // اگر بلوک openGraph را دستی بسازیم، Next تصویر فایل‌کانونشن را اضافه نمی‌کند،
  // پس اینجا صریح به آن اشاره می‌کنیم.
  const ogImage = absoluteUrl(`${canonical}/opengraph-image`);

  // آهنگ خصوصی یا در حال پردازش نباید ایندکس شود
  const indexable = track.visibility === 'public' && track.status === 'ready';

  return {
    title,
    description,
    alternates: { canonical },
    keywords: [track.title, artist, track.genre, ...(track.tags ?? [])].filter(
      Boolean,
    ) as string[],
    robots: indexable ? undefined : { index: false, follow: true },
    openGraph: {
      type: 'music.song',
      title,
      description,
      url: absoluteUrl(canonical),
      siteName: SITE_NAME,
      locale: 'fa_IR',
      images: [{ url: ogImage, width: 1200, height: 630, alt: title }],
    },
    twitter: {
      card: 'summary_large_image',
      title,
      description,
      images: [ogImage],
    },
    other: {
      // متادیتای اختصاصی OpenGraph برای موسیقی — فیسبوک و تلگرام می‌خوانند
      ...(track.duration ? { 'music:duration': String(track.duration) } : {}),
      ...(artist ? { 'music:musician': absoluteUrl(routes.artist(artist)) } : {}),
    },
  };
}

export default async function TrackPage({ params }: PageProps) {
  const { id: param } = await params;
  const track = await loadTrack(param);
  if (!track) notFound();

  // اگر با URL خام UUID آمده، ۳۰۸ به شکل canonical تا لینک‌ها یکی شوند
  if (!isCanonicalSlug(param, track.title, track.id)) {
    permanentRedirect(routes.track(track.title, track.id));
  }

  const artist = track.user?.username;
  const moreByArtist = artist
    ? (await getTracksByUsername(artist)).filter((item) => item.id !== track.id).slice(0, 5)
    : [];

  const crumbs = [
    { name: 'خانه', path: routes.home() },
    ...(artist ? [{ name: artist, path: routes.artist(artist) }] : []),
    { name: track.title, path: routes.track(track.title, track.id) },
  ];

  return (
    <>
      <JsonLd data={graph(trackSchema(track), breadcrumbSchema(crumbs))} />
      <Breadcrumbs items={crumbs} />

      <article>
        <div className="flex flex-col gap-6 sm:flex-row">
          <div className="w-full max-w-[280px] shrink-0">
            <Cover
              src={track.coverUrl}
              alt={artist ? `کاور آهنگ ${track.title} از ${artist}` : `کاور آهنگ ${track.title}`}
              sizes="(max-width: 640px) 90vw, 280px"
              priority
            />
          </div>

          <div className="min-w-0 flex-1">
            <h1 className="text-2xl font-bold sm:text-3xl">{track.title}</h1>

            {artist && (
              <p className="mt-1 text-sm text-neutral-400">
                از{' '}
                <Link href={routes.artist(artist)} className="text-emerald-400 hover:underline">
                  {artist}
                </Link>
              </p>
            )}

            <div className="mt-4 flex items-center gap-4">
              <PlayButton track={track} size="lg" />
              <dl className="flex flex-wrap gap-x-5 gap-y-1 text-xs text-neutral-400">
                <Stat label="پخش" value={formatCount(track.playCount)} />
                <Stat label="پسند" value={formatCount(track.likesCount)} />
                <Stat label="نظر" value={formatCount(track.commentsCount)} />
                <Stat label="مدت" value={formatDuration(track.duration)} />
              </dl>
            </div>

            {track.description && (
              <p className="mt-5 whitespace-pre-line text-sm leading-7 text-neutral-300">
                {track.description}
              </p>
            )}

            <p className="mt-5 text-xs text-neutral-500">
              منتشر شده در {formatDate(track.createdAt)}
              {track.genre && (
                <>
                  {' · سبک '}
                  <Link
                    href={routes.genre(track.genre)}
                    className="text-emerald-400 hover:underline"
                  >
                    {track.genre}
                  </Link>
                </>
              )}
            </p>

            {track.tags && track.tags.length > 0 && (
              <ul className="mt-3 flex flex-wrap gap-2">
                {track.tags.map((tag) => (
                  <li key={tag}>
                    <span className="rounded-full border border-neutral-800 px-3 py-1 text-[11px] text-neutral-400">
                      #{tag}
                    </span>
                  </li>
                ))}
              </ul>
            )}
          </div>
        </div>

        {moreByArtist.length > 0 && artist && (
          <section className="mt-14">
            <h2 className="mb-4 text-lg font-semibold">
              آهنگ‌های دیگر {artist}
            </h2>
            <TrackGrid tracks={moreByArtist} />
          </section>
        )}
      </article>
    </>
  );
}

function Stat({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex gap-1">
      <dt className="text-neutral-500">{label}</dt>
      <dd className="tabular-nums text-neutral-300">{value}</dd>
    </div>
  );
}

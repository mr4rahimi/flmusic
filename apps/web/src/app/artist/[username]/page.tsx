import type { Metadata } from 'next';
import Image from 'next/image';
import { notFound } from 'next/navigation';

import { Breadcrumbs } from '@/components/Breadcrumbs';
import { JsonLd } from '@/components/JsonLd';
import { TrackGrid } from '@/components/TrackGrid';
import { getProfile, getTracksByUsername } from '@/lib/api';
import { SITE_NAME } from '@/lib/env';
import { formatCount, formatDate } from '@/lib/format';
import {
  artistSchema,
  breadcrumbSchema,
  graph,
  profilePageSchema,
} from '@/lib/jsonld';
import { absoluteUrl, mediaUrl, metaDescription, routes } from '@/lib/seo';

export const revalidate = 300;

type PageProps = { params: Promise<{ username: string }> };

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { username: raw } = await params;
  const username = decodeURIComponent(raw);
  const profile = await getProfile(username);

  if (!profile) {
    return { title: 'هنرمند پیدا نشد', robots: { index: false, follow: false } };
  }

  const title = `${profile.username} — آهنگ‌ها و پروفایل`;
  const description = metaDescription(
    profile.bio ||
      `صفحه‌ی ${profile.username} در ${SITE_NAME}: ${formatCount(profile.tracksCount)} آهنگ و ${formatCount(profile.followersCount)} دنبال‌کننده. همه‌ی آثار را آنلاین بشنوید.`,
  );
  const canonical = routes.artist(profile.username);
  const ogImage = absoluteUrl(`${canonical}/opengraph-image`);

  return {
    title,
    description,
    alternates: { canonical },
    openGraph: {
      type: 'profile',
      username: profile.username,
      title,
      description,
      url: absoluteUrl(canonical),
      siteName: SITE_NAME,
      locale: 'fa_IR',
      images: [{ url: ogImage, width: 1200, height: 630, alt: profile.username }],
    },
    twitter: {
      card: 'summary_large_image',
      title,
      description,
      images: [ogImage],
    },
  };
}

export default async function ArtistPage({ params }: PageProps) {
  const { username: raw } = await params;
  const username = decodeURIComponent(raw);

  const [profile, tracks] = await Promise.all([
    getProfile(username),
    getTracksByUsername(username),
  ]);

  if (!profile) notFound();

  const avatar = mediaUrl(profile.avatarUrl);
  const crumbs = [
    { name: 'خانه', path: routes.home() },
    { name: profile.username, path: routes.artist(profile.username) },
  ];

  return (
    <>
      <JsonLd
        data={graph(
          artistSchema(profile, tracks),
          profilePageSchema(profile),
          breadcrumbSchema(crumbs),
        )}
      />
      <Breadcrumbs items={crumbs} />

      <header className="mb-10 flex flex-col items-start gap-5 sm:flex-row sm:items-center">
        <div className="relative h-24 w-24 shrink-0 overflow-hidden rounded-full bg-neutral-800">
          {avatar && (
            <Image
              src={avatar}
              alt={`تصویر پروفایل ${profile.username}`}
              fill
              sizes="96px"
              priority
              className="object-cover"
            />
          )}
        </div>

        <div className="min-w-0">
          <h1 className="flex items-center gap-2 text-2xl font-bold sm:text-3xl">
            {profile.username}
            {profile.verifiedStatus === 'verified' && (
              <span
                title="حساب تأییدشده"
                aria-label="حساب تأییدشده"
                className="text-emerald-400"
              >
                ✓
              </span>
            )}
          </h1>

          {profile.bio && (
            <p className="mt-2 max-w-2xl text-sm leading-7 text-neutral-300">
              {profile.bio}
            </p>
          )}

          <dl className="mt-3 flex flex-wrap gap-x-5 gap-y-1 text-xs text-neutral-400">
            <Stat label="آهنگ" value={formatCount(profile.tracksCount)} />
            <Stat label="دنبال‌کننده" value={formatCount(profile.followersCount)} />
            <Stat label="دنبال‌شده" value={formatCount(profile.followingCount)} />
            <Stat label="عضویت" value={formatDate(profile.createdAt)} />
          </dl>
        </div>
      </header>

      <section>
        <h2 className="mb-4 text-lg font-semibold">
          آهنگ‌های {profile.username}
        </h2>
        <TrackGrid
          tracks={tracks}
          priorityCount={5}
          emptyMessage={`${profile.username} هنوز آهنگی منتشر نکرده است.`}
        />
      </section>
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

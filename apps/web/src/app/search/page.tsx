import type { Metadata } from 'next';
import Image from 'next/image';
import Link from 'next/link';

import { TrackGrid } from '@/components/TrackGrid';
import { search } from '@/lib/api';
import { SITE_NAME } from '@/lib/env';
import { formatCount } from '@/lib/format';
import { mediaUrl, routes } from '@/lib/seo';

type PageProps = { searchParams: Promise<{ q?: string }> };

/**
 * صفحات نتیجه‌ی جستجو نباید ایندکس شوند: محتوای تکراری تولید می‌کنند
 * و بودجه‌ی خزش را هدر می‌دهند. follow می‌ماند تا لینک‌های داخلی دنبال شوند.
 */
export async function generateMetadata({ searchParams }: PageProps): Promise<Metadata> {
  const { q } = await searchParams;
  return {
    title: q ? `جستجوی «${q}»` : 'جستجو',
    description: `جستجوی آهنگ و هنرمند در ${SITE_NAME}.`,
    robots: { index: false, follow: true },
    alternates: { canonical: '/search' },
  };
}

export default async function SearchPage({ searchParams }: PageProps) {
  const { q } = await searchParams;
  const query = (q ?? '').trim();
  const { tracks = [], users = [] } = query
    ? await search(query)
    : { tracks: [], users: [] };

  return (
    <>
      <h1 className="text-2xl font-bold">
        {query ? <>نتایج جستجو برای «{query}»</> : 'جستجو'}
      </h1>

      {!query && (
        <p className="mt-2 text-sm text-neutral-400">
          نام آهنگ یا هنرمند را در کادر بالا بنویسید.
        </p>
      )}

      {query && users.length > 0 && (
        <section className="mt-8">
          <h2 className="mb-4 text-lg font-semibold">هنرمندان</h2>
          <ul className="flex flex-wrap gap-4">
            {users.map((user) => {
              const avatar = mediaUrl(user.avatarUrl);
              return (
                <li key={user.id}>
                  <Link
                    href={routes.artist(user.username)}
                    className="flex items-center gap-3 rounded-xl border border-neutral-800 px-4 py-2 transition hover:border-emerald-500"
                  >
                    <span className="relative h-9 w-9 overflow-hidden rounded-full bg-neutral-800">
                      {avatar && (
                        <Image
                          src={avatar}
                          alt=""
                          fill
                          sizes="36px"
                          className="object-cover"
                        />
                      )}
                    </span>
                    <span className="text-sm">
                      {user.username}
                      {typeof user.followersCount === 'number' && (
                        <span className="block text-[11px] text-neutral-500">
                          {formatCount(user.followersCount)} دنبال‌کننده
                        </span>
                      )}
                    </span>
                  </Link>
                </li>
              );
            })}
          </ul>
        </section>
      )}

      {query && (
        <section className="mt-10">
          <h2 className="mb-4 text-lg font-semibold">آهنگ‌ها</h2>
          <TrackGrid
            tracks={tracks}
            emptyMessage={`چیزی برای «${query}» پیدا نشد.`}
          />
        </section>
      )}
    </>
  );
}

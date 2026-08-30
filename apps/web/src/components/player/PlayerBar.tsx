'use client';

import Link from 'next/link';
import { usePlayer } from './PlayerProvider';
import { formatDuration } from '@/lib/format';
import { mediaUrl, routes } from '@/lib/seo';
import { singerOf } from '@/lib/types';

/** نوار پخش چسبیده به پایین صفحه؛ تا وقتی چیزی پخش نشده رندر نمی‌شود. */
export function PlayerBar() {
  const { current, isPlaying, toggle, position, duration, seek } = usePlayer();
  if (!current) return null;

  const cover = mediaUrl(current.coverUrl);
  const singer = singerOf(current);
  const total = duration || current.duration || 0;

  return (
    <div className="fixed inset-x-0 bottom-0 z-50 border-t border-neutral-800 bg-neutral-950/95 backdrop-blur">
      <div className="mx-auto flex max-w-6xl items-center gap-3 px-4 py-2">
        {/* کاور ۴۸ پیکسلی نوار پخش؛ next/image اینجا سودی ندارد و فقط
            یک درخواست بهینه‌سازی اضافه می‌سازد */}
        {cover && (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={cover}
            alt=""
            width={48}
            height={48}
            className="h-12 w-12 shrink-0 rounded-lg object-cover"
          />
        )}

        <div className="min-w-0 flex-1">
          <Link
            href={routes.track(current.title, current.id)}
            className="block truncate text-sm font-medium hover:underline"
          >
            {current.title}
          </Link>
          {singer && (
            <Link
              href={routes.singer(singer)}
              className="block truncate text-xs text-neutral-400 hover:underline"
            >
              {singer}
            </Link>
          )}
        </div>

        <div className="hidden items-center gap-2 sm:flex">
          <span className="tabular-nums text-xs text-neutral-400">
            {formatDuration(position)}
          </span>
          <input
            type="range"
            min={0}
            max={total || 1}
            value={Math.min(position, total || 1)}
            onChange={(event) => seek(Number(event.target.value))}
            aria-label="جابه‌جایی در آهنگ"
            className="h-1 w-40 accent-emerald-500 lg:w-64"
          />
          <span className="tabular-nums text-xs text-neutral-400">
            {formatDuration(total)}
          </span>
        </div>

        <button
          type="button"
          onClick={toggle}
          aria-label={isPlaying ? 'توقف' : 'پخش'}
          className="grid h-10 w-10 shrink-0 place-items-center rounded-full bg-emerald-500 text-black hover:bg-emerald-400"
        >
          <svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true" className="h-5 w-5">
            {isPlaying ? <path d="M8 5h3v14H8zM13 5h3v14h-3z" /> : <path d="M8 5.14v13.72L19 12z" />}
          </svg>
        </button>
      </div>
    </div>
  );
}

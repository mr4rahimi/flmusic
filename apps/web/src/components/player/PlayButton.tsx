'use client';

import { usePlayer } from './PlayerProvider';
import type { Track } from '@/lib/types';

interface PlayButtonProps {
  track: Track;
  size?: 'sm' | 'lg';
}

/**
 * دکمه‌ی پخش. جزیره‌ی کوچک کلاینتی روی محتوای سرور-رندر —
 * متن و لینک‌های صفحه همچنان در HTML اولیه برای خزنده موجودند.
 */
export function PlayButton({ track, size = 'sm' }: PlayButtonProps) {
  const { play, toggle, isPlaying, isCurrent } = usePlayer();
  const active = isCurrent(track.id) && isPlaying;
  const disabled = !track.audioUrl;

  const dimensions = size === 'lg' ? 'h-14 w-14' : 'h-10 w-10';

  return (
    <button
      type="button"
      disabled={disabled}
      aria-label={active ? `توقف ${track.title}` : `پخش ${track.title}`}
      onClick={() => (isCurrent(track.id) ? toggle() : play(track))}
      className={`${dimensions} grid place-items-center rounded-full bg-emerald-500 text-black transition hover:bg-emerald-400 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-emerald-400 disabled:cursor-not-allowed disabled:bg-neutral-700 disabled:text-neutral-500`}
    >
      <svg
        viewBox="0 0 24 24"
        fill="currentColor"
        aria-hidden="true"
        className={size === 'lg' ? 'h-6 w-6' : 'h-5 w-5'}
      >
        {active ? (
          <path d="M8 5h3v14H8zM13 5h3v14h-3z" />
        ) : (
          <path d="M8 5.14v13.72L19 12z" />
        )}
      </svg>
    </button>
  );
}

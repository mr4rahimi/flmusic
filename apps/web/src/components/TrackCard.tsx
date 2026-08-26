import Link from 'next/link';
import { Cover } from './Cover';
import { PlayButton } from './player/PlayButton';
import { formatCount, formatDuration } from '@/lib/format';
import { routes } from '@/lib/seo';
import type { Track } from '@/lib/types';

interface TrackCardProps {
  track: Track;
  /** فقط برای چند کارت اول صفحه، تا LCP سریع‌تر شود */
  priority?: boolean;
}

export function TrackCard({ track, priority }: TrackCardProps) {
  const artist = track.user?.username;

  return (
    <article className="group">
      <div className="relative">
        <Link
          href={routes.track(track.title, track.id)}
          className="block"
          aria-label={track.title}
        >
          <Cover
            src={track.coverUrl}
            alt={artist ? `کاور آهنگ ${track.title} از ${artist}` : `کاور آهنگ ${track.title}`}
            sizes="(max-width: 640px) 45vw, (max-width: 1024px) 30vw, 220px"
            priority={priority}
          />
        </Link>
        <div className="absolute bottom-2 left-2 opacity-0 transition group-hover:opacity-100 focus-within:opacity-100">
          <PlayButton track={track} />
        </div>
      </div>

      <h3 className="mt-2 truncate text-sm font-medium">
        <Link href={routes.track(track.title, track.id)} className="hover:underline">
          {track.title}
        </Link>
      </h3>

      {artist && (
        <p className="truncate text-xs text-neutral-400">
          <Link href={routes.artist(artist)} className="hover:underline">
            {artist}
          </Link>
        </p>
      )}

      <p className="mt-1 flex items-center gap-2 text-[11px] text-neutral-500">
        <span>{formatCount(track.playCount)} پخش</span>
        <span aria-hidden="true">·</span>
        <span>{formatDuration(track.duration)}</span>
      </p>
    </article>
  );
}

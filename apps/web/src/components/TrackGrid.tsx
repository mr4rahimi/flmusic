import { TrackCard } from './TrackCard';
import type { Track } from '@/lib/types';

interface TrackGridProps {
  tracks: Track[];
  /** تعداد کارت‌هایی که با priority بارگذاری می‌شوند (بالای صفحه) */
  priorityCount?: number;
  emptyMessage?: string;
}

export function TrackGrid({
  tracks,
  priorityCount = 0,
  emptyMessage = 'هنوز آهنگی اینجا نیست.',
}: TrackGridProps) {
  if (tracks.length === 0) {
    return <p className="py-8 text-sm text-neutral-500">{emptyMessage}</p>;
  }

  return (
    <ul className="grid grid-cols-2 gap-x-4 gap-y-6 sm:grid-cols-3 lg:grid-cols-5">
      {tracks.map((track, index) => (
        <li key={track.id}>
          <TrackCard track={track} priority={index < priorityCount} />
        </li>
      ))}
    </ul>
  );
}

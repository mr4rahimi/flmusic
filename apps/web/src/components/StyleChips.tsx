import Link from 'next/link';
import { routes } from '@/lib/seo';

/**
 * فهرست سبک‌ها به شکل چیپ.
 * «سبک» همان مقدارهای `track.tags` است (عاشقانه، شاد، …) — نه ستون `genre`
 * که در واقع نام خواننده را نگه می‌دارد.
 */
export function StyleChips({
  styles,
  label,
  className,
}: {
  styles: string[];
  label?: string;
  className?: string;
}) {
  if (styles.length === 0) return null;

  return (
    <div className={className}>
      {label && <p className="mb-2 text-xs text-neutral-500">{label}</p>}
      <ul className="flex flex-wrap gap-2">
        {styles.map((style) => (
          <li key={style}>
            <Link
              href={routes.style(style)}
              className="inline-block rounded-full border border-neutral-800 px-3 py-1 text-[11px] text-neutral-400 transition hover:border-emerald-500 hover:text-emerald-400"
            >
              {style}
            </Link>
          </li>
        ))}
      </ul>
    </div>
  );
}

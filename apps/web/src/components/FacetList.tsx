import Link from 'next/link';
import type { Facet } from '@/lib/api';
import { toFaDigits } from '@/lib/format';

/** فهرست چیپی خواننده‌ها یا سبک‌ها به‌همراه تعداد آهنگ. */
export function FacetList({
  items,
  href,
  emptyMessage,
}: {
  items: Facet[];
  href: (name: string) => string;
  emptyMessage: string;
}) {
  if (items.length === 0) {
    return <p className="text-sm text-neutral-500">{emptyMessage}</p>;
  }

  return (
    <ul className="flex flex-wrap gap-3">
      {items.map(({ name, count }) => (
        <li key={name}>
          <Link
            href={href(name)}
            className="inline-flex items-center gap-2 rounded-full border border-neutral-800 px-4 py-2 text-sm transition hover:border-emerald-500 hover:text-emerald-400"
          >
            {name}
            <span className="tabular-nums text-xs text-neutral-500">
              {toFaDigits(count)}
            </span>
          </Link>
        </li>
      ))}
    </ul>
  );
}

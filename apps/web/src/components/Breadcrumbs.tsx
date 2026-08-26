import Link from 'next/link';

export interface Crumb {
  name: string;
  path: string;
}

/**
 * مسیر راهنما. نسخه‌ی بصری آن؛ نسخه‌ی ساختاریافته (BreadcrumbList)
 * جداگانه در JSON-LD صفحه تزریق می‌شود.
 */
export function Breadcrumbs({ items }: { items: Crumb[] }) {
  return (
    <nav aria-label="مسیر صفحه" className="mb-4 text-xs text-neutral-500">
      <ol className="flex flex-wrap items-center gap-1">
        {items.map((item, index) => {
          const isLast = index === items.length - 1;
          return (
            <li key={item.path} className="flex items-center gap-1">
              {isLast ? (
                <span aria-current="page" className="text-neutral-300">
                  {item.name}
                </span>
              ) : (
                <Link href={item.path} className="hover:text-white">
                  {item.name}
                </Link>
              )}
              {!isLast && <span aria-hidden="true">/</span>}
            </li>
          );
        })}
      </ol>
    </nav>
  );
}

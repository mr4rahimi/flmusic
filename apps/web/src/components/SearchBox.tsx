'use client';

import { useRouter, useSearchParams } from 'next/navigation';
import { useState } from 'react';
import { routes } from '@/lib/seo';

/** فرم جستجو — با GET کار می‌کند تا بدون جاوااسکریپت هم قابل استفاده باشد. */
export function SearchBox({ className }: { className?: string }) {
  const router = useRouter();
  const params = useSearchParams();
  const [value, setValue] = useState(params.get('q') ?? '');

  return (
    <form
      role="search"
      action="/search"
      method="get"
      onSubmit={(event) => {
        event.preventDefault();
        if (value.trim()) router.push(routes.search(value.trim()));
      }}
      className={className}
    >
      <label htmlFor="site-search" className="sr-only">
        جستجوی آهنگ، خواننده و کاربر
      </label>
      <input
        id="site-search"
        name="q"
        type="search"
        value={value}
        onChange={(event) => setValue(event.target.value)}
        placeholder="جستجوی آهنگ یا خواننده…"
        className="w-full rounded-full border border-neutral-800 bg-neutral-900 px-4 py-2 text-sm outline-none placeholder:text-neutral-500 focus:border-emerald-500"
      />
    </form>
  );
}

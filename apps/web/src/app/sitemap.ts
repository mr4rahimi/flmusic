import type { MetadataRoute } from 'next';

import { getGenres, getNewTracks, getTrendingTracks } from '@/lib/api';
import { SITE_URL } from '@/lib/env';
import { routes } from '@/lib/seo';
import type { Track } from '@/lib/types';

/**
 * sitemap.xml
 *
 * محدودیت‌ها: هر sitemap حداکثر ۵۰٬۰۰۰ آدرس. فعلاً از تعداد کل آهنگ‌ها
 * خیلی پایین‌تریم، ولی وقتی نزدیک شد باید به generateSitemaps مهاجرت کنیم
 * (توضیح در docs/02-seo.md بخش «رشد sitemap»).
 *
 * چون هیچ endpointی «همه‌ی آهنگ‌ها» را نمی‌دهد، تا سقف مشخصی از
 * جدیدترین‌ها صفحه‌به‌صفحه می‌خوانیم.
 */

const MAX_TRACKS = 5000;
const PAGE_SIZE = 100;

export const revalidate = 3600;

async function collectTracks(): Promise<Track[]> {
  const collected: Track[] = [];

  for (let page = 1; collected.length < MAX_TRACKS; page += 1) {
    const batch = await getNewTracks(page, PAGE_SIZE);
    if (batch.length === 0) break;
    collected.push(...batch);
    if (batch.length < PAGE_SIZE) break;
  }

  return collected;
}

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const [tracks, trending, genres] = await Promise.all([
    collectTracks(),
    getTrendingTracks(1, 50),
    getGenres(),
  ]);

  const now = new Date();

  const staticPages: MetadataRoute.Sitemap = [
    { url: `${SITE_URL}/`, lastModified: now, changeFrequency: 'daily', priority: 1 },
    {
      url: `${SITE_URL}${routes.trending()}`,
      lastModified: now,
      changeFrequency: 'daily',
      priority: 0.9,
    },
    {
      url: `${SITE_URL}${routes.newest()}`,
      lastModified: now,
      changeFrequency: 'hourly',
      priority: 0.9,
    },
    {
      url: `${SITE_URL}/genre`,
      lastModified: now,
      changeFrequency: 'weekly',
      priority: 0.7,
    },
  ];

  const genrePages: MetadataRoute.Sitemap = genres.map(({ genre }) => ({
    url: `${SITE_URL}${routes.genre(genre)}`,
    lastModified: now,
    changeFrequency: 'daily',
    priority: 0.7,
  }));

  // آهنگ‌های داغ اولویت بالاتری می‌گیرند تا زودتر بازخزیده شوند
  const trendingIds = new Set(trending.map((track) => track.id));

  const trackPages: MetadataRoute.Sitemap = tracks.map((track) => ({
    url: `${SITE_URL}${routes.track(track.title, track.id)}`,
    lastModified: new Date(track.updatedAt || track.createdAt),
    changeFrequency: 'weekly',
    priority: trendingIds.has(track.id) ? 0.8 : 0.6,
  }));

  // هر هنرمند یک‌بار — از روی آهنگ‌هایش استخراج می‌شود
  const usernames = new Set(
    tracks.map((track) => track.user?.username).filter(Boolean) as string[],
  );

  const artistPages: MetadataRoute.Sitemap = [...usernames].map((username) => ({
    url: `${SITE_URL}${routes.artist(username)}`,
    lastModified: now,
    changeFrequency: 'weekly',
    priority: 0.7,
  }));

  return [...staticPages, ...genrePages, ...artistPages, ...trackPages];
}

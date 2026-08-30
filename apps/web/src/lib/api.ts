import { API_URL, REVALIDATE } from './env';
import { singerOf, stylesOf } from './types';
import type { Playlist, Profile, SearchResults, Track } from './types';

/** خطای HTTP همراه با کد وضعیت تا صفحات بتوانند ۴۰۴ واقعی برگردانند. */
export class ApiError extends Error {
  constructor(
    readonly status: number,
    readonly path: string,
  ) {
    super(`API ${status} on ${path}`);
    this.name = 'ApiError';
  }
}

interface FetchOptions {
  /** ثانیه؛ پیش‌فرض REVALIDATE. مقدار 0 یعنی بدون کش. */
  revalidate?: number;
  tags?: string[];
}

async function apiGet<T>(path: string, options: FetchOptions = {}): Promise<T> {
  const revalidate = options.revalidate ?? REVALIDATE;

  const response = await fetch(`${API_URL}${path}`, {
    headers: { Accept: 'application/json' },
    next: revalidate === 0 ? { revalidate: 0 } : { revalidate, tags: options.tags },
  });

  if (!response.ok) throw new ApiError(response.status, path);
  return response.json() as Promise<T>;
}

/**
 * مثل apiGet ولی به‌جای پرتاب خطا مقدار پیش‌فرض می‌دهد.
 * برای بخش‌های جانبی صفحه که نباید کل رندر را خراب کنند.
 */
async function apiGetSafe<T>(
  path: string,
  fallback: T,
  options: FetchOptions = {},
): Promise<T> {
  try {
    return await apiGet<T>(path, options);
  } catch (error) {
    console.error('[api] fetch failed:', path, error);
    return fallback;
  }
}

/**
 * پاسخ‌های API سه شکل دارند: آرایه‌ی خام (tracks/user/:username)،
 * `{ data: [...] }` (feed و search) و `{ items: [...] }`. هر سه را یکدست می‌کنیم.
 */
function toList<T>(payload: unknown): T[] {
  if (Array.isArray(payload)) return payload as T[];
  if (payload && typeof payload === 'object') {
    const box = payload as { data?: unknown; items?: unknown };
    if (Array.isArray(box.data)) return box.data as T[];
    if (Array.isArray(box.items)) return box.items as T[];
  }
  return [];
}

/** یک ردیف از فهرست‌های دسته‌بندی (خواننده یا سبک) به‌همراه تعداد آهنگ. */
export interface Facet {
  name: string;
  count: number;
}

/** آهنگ‌ها را بر اساس کلیدهای استخراج‌شده می‌شمارد و نزولی مرتب می‌کند. */
function countBy(tracks: Track[], keysOf: (track: Track) => string[]): Facet[] {
  const counts = new Map<string, number>();
  for (const track of tracks) {
    for (const key of keysOf(track)) {
      counts.set(key, (counts.get(key) ?? 0) + 1);
    }
  }
  return [...counts.entries()]
    .map(([name, count]) => ({ name, count }))
    .sort((a, b) => b.count - a.count || a.name.localeCompare(b.name, 'fa'));
}

/**
 * فقط برای endpointهایی که موجودیت کامل برمی‌گردانند.
 * خروجی feed و search سمت سرور فیلتر شده و اصلاً فیلد visibility/status ندارد،
 * پس آنجا این تابع را صدا نمی‌زنیم وگرنه همه‌چیز حذف می‌شود.
 */
const onlyPublicReady = (tracks: Track[]) =>
  tracks.filter(
    (t) =>
      (t.visibility ?? 'public') === 'public' && (t.status ?? 'ready') === 'ready',
  );

// ---------------------------------------------------------------------------
// Feed — GET /feed/{trending,new}
// ---------------------------------------------------------------------------

export async function getTrendingTracks(page = 1, limit = 24): Promise<Track[]> {
  const payload = await apiGetSafe<unknown>(
    `/feed/trending?page=${page}&limit=${limit}`,
    [],
    { tags: ['feed'] },
  );
  return toList<Track>(payload);
}

export async function getNewTracks(page = 1, limit = 24): Promise<Track[]> {
  const payload = await apiGetSafe<unknown>(
    `/feed/new?page=${page}&limit=${limit}`,
    [],
    { tags: ['feed'] },
  );
  return toList<Track>(payload);
}

/**
 * نمونه‌ای از جدیدترین آهنگ‌ها برای ساختن فهرست‌های دسته‌بندی وقتی API
 * endpoint تجمیعی ندارد. روی سرور پروداکشن `/feed/genres` هنوز ۴۰۴ می‌دهد،
 * پس در عمل همین مسیر اجرا می‌شود — جزئیات در docs/05-api-integration.md.
 */
const SAMPLE_SIZE = 300;

async function sampleTracks(size = SAMPLE_SIZE): Promise<Track[]> {
  const batches = await Promise.all(
    Array.from({ length: Math.ceil(size / 100) }, (_, i) =>
      getNewTracks(i + 1, 100),
    ),
  );
  return batches.flat();
}

/**
 * آهنگ‌های یک خواننده.
 *
 * ⚠️ ستون `genre` در API در عمل «نام خواننده» را نگه می‌دارد (توضیح در
 * `types.ts`)، پس endpointهای `/feed/genre*` منبع داده‌ی صفحات خواننده‌اند.
 * اگر endpoint اختصاصی روی سرور نباشد، به فیلتر روی جدیدترین‌ها برمی‌گردیم
 * تا صفحه خالی نماند.
 */
export async function getTracksBySinger(singer: string, limit = 48): Promise<Track[]> {
  try {
    const payload = await apiGet<unknown>(
      `/feed/genre/${encodeURIComponent(singer)}?limit=${limit}`,
      { tags: [`singer:${singer}`] },
    );
    return toList<Track>(payload);
  } catch {
    const needle = singer.toLowerCase();
    return (await sampleTracks())
      .filter((t) => (singerOf(t) ?? '').toLowerCase() === needle)
      .slice(0, limit);
  }
}

/** فهرست خواننده‌ها به‌همراه تعداد آهنگ — برای صفحه‌ی /artists و sitemap. */
export async function getSingers(): Promise<Facet[]> {
  try {
    const rows = await apiGet<{ genre: string; count: number }[]>('/feed/genres', {
      tags: ['singers'],
    });
    return rows
      .filter((row) => row.genre?.trim())
      .map((row) => ({ name: row.genre.trim(), count: row.count }));
  } catch {
    // fallback: خواننده‌ها را از روی نمونه‌ی جدیدترین‌ها استخراج می‌کنیم
    return countBy(await sampleTracks(), (track) => {
      const singer = singerOf(track);
      return singer ? [singer] : [];
    });
  }
}

// ---------------------------------------------------------------------------
// سبک‌ها — روی `track.tags` سوارند.
// API فعلاً endpoint اختصاصی ندارد؛ اول امتحانش می‌کنیم و بعد fallback.
// ---------------------------------------------------------------------------

export async function getStyles(): Promise<Facet[]> {
  try {
    const rows = await apiGet<{ tag: string; count: number }[]>('/feed/tags', {
      tags: ['styles'],
    });
    return rows
      .filter((row) => row.tag?.trim())
      .map((row) => ({ name: row.tag.trim(), count: row.count }));
  } catch {
    return countBy(await sampleTracks(), stylesOf);
  }
}

export async function getTracksByStyle(style: string, limit = 48): Promise<Track[]> {
  try {
    const payload = await apiGet<unknown>(
      `/feed/tag/${encodeURIComponent(style)}?limit=${limit}`,
      { tags: [`style:${style}`] },
    );
    return toList<Track>(payload);
  } catch {
    const needle = style.toLowerCase();
    return (await sampleTracks())
      .filter((track) => stylesOf(track).some((t) => t.toLowerCase() === needle))
      .slice(0, limit);
  }
}

// ---------------------------------------------------------------------------
// Tracks
// ---------------------------------------------------------------------------

export async function getTrack(id: string): Promise<Track | null> {
  try {
    return await apiGet<Track>(`/tracks/${id}`, { tags: [`track:${id}`] });
  } catch (error) {
    if (error instanceof ApiError && (error.status === 404 || error.status === 403)) {
      return null;
    }
    throw error;
  }
}

export async function getTracksByUsername(username: string): Promise<Track[]> {
  const payload = await apiGetSafe<unknown>(
    `/tracks/user/${encodeURIComponent(username)}`,
    [],
    { tags: [`user-tracks:${username}`] },
  );
  // این endpoint موجودیت کامل می‌دهد، پس فیلتر لازم است
  return onlyPublicReady(toList<Track>(payload));
}

// ---------------------------------------------------------------------------
// Profiles
// ---------------------------------------------------------------------------

export async function getProfile(username: string): Promise<Profile | null> {
  try {
    return await apiGet<Profile>(`/profiles/${encodeURIComponent(username)}`, {
      tags: [`profile:${username}`],
    });
  } catch (error) {
    if (error instanceof ApiError && error.status === 404) return null;
    throw error;
  }
}

// ---------------------------------------------------------------------------
// Playlists
// ---------------------------------------------------------------------------

export async function getPlaylist(id: string): Promise<Playlist | null> {
  try {
    return await apiGet<Playlist>(`/playlists/${id}`, { tags: [`playlist:${id}`] });
  } catch (error) {
    if (error instanceof ApiError && error.status === 404) return null;
    throw error;
  }
}

// ---------------------------------------------------------------------------
// Search — GET /search?q=&type=
// ---------------------------------------------------------------------------

export async function search(
  query: string,
  limit = 24,
): Promise<SearchResults> {
  if (!query.trim()) return { tracks: [], users: [] };

  // با type=all هر بخش حداکثر ۵ نتیجه می‌دهد، پس دو درخواست جدا می‌زنیم
  const [tracks, users] = await Promise.all([
    apiGetSafe<unknown>(
      `/search?q=${encodeURIComponent(query)}&type=tracks&limit=${limit}`,
      [],
      { revalidate: 60 },
    ),
    apiGetSafe<unknown>(
      `/search?q=${encodeURIComponent(query)}&type=users&limit=12`,
      [],
      { revalidate: 60 },
    ),
  ]);

  return { tracks: toList<Track>(tracks), users: toList<Profile>(users) };
}

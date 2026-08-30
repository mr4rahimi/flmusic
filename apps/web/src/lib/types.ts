/**
 * شکل داده‌هایی که NestJS برمی‌گرداند.
 * مرجع: فایل‌های entity و dto در apps/api/src/modules
 */

export type TrackVisibility = 'public' | 'private';
export type TrackStatus = 'processing' | 'ready' | 'failed';
export type UserRole = 'user' | 'artist' | 'admin';
export type VerifiedStatus = 'none' | 'pending' | 'verified';

export interface TrackUser {
  id: string;
  username: string;
  avatarUrl: string | null;
  role?: UserRole;
  verifiedStatus?: VerifiedStatus;
}

export interface Track {
  id: string;
  userId?: string;
  user?: TrackUser;
  title: string;
  description: string | null;
  coverUrl: string | null;
  audioUrl: string | null;
  duration: number | null;
  waveformData?: number[] | null;
  /**
   * ⚠️ نام ستون گمراه‌کننده است: فرم آپلود اپ فندوق «نام خواننده» را در
   * همین فیلد می‌فرستد (apps/mobile/.../upload_provider.dart → 'genre': artistName).
   * پس این مقدار **خواننده** است، نه سبک. در UI با helper زیر خوانده شود.
   */
  genre: string | null;
  /** برچسب‌های آهنگ (عاشقانه، شاد، …) — همان چیزی که کاربر «سبک» می‌نامد. */
  tags: string[] | null;
  /** خروجی feed و search این دو فیلد را ندارد؛ آنجا از قبل فیلتر شده‌اند. */
  visibility?: TrackVisibility;
  status?: TrackStatus;
  playCount: number;
  likesCount: number;
  commentsCount: number;
  repostsCount?: number;
  createdAt: string;
  updatedAt?: string;
}

/** خواننده‌ی آهنگ — مقدار واقعی ستون `genre`. */
export const singerOf = (track: Track): string | null =>
  track.genre?.trim() || null;

/** سبک‌های آهنگ — مقدار واقعی ستون `tags`. */
export const stylesOf = (track: Track): string[] =>
  (track.tags ?? []).map((tag) => tag.trim()).filter(Boolean);

export interface Profile {
  id: string;
  username: string;
  role: UserRole;
  verifiedStatus: VerifiedStatus;
  avatarUrl: string | null;
  bio: string | null;
  followersCount: number;
  followingCount: number;
  tracksCount: number;
  createdAt: string;
  /**
   * API این فیلد را برمی‌گرداند ولی هرگز در صفحات عمومی رندر نمی‌شود.
   * توضیح در docs/05-api-integration.md بخش «نشت ایمیل».
   */
  email?: string;
}

export interface Playlist {
  id: string;
  title: string;
  description?: string | null;
  coverUrl?: string | null;
  userId: string;
  user?: TrackUser;
  tracks?: Track[];
  createdAt: string;
}

/** خروجی صفحه‌بندی‌شده‌ی feed */
export interface Paginated<T> {
  items: T[];
  total: number;
  page: number;
  limit: number;
}

export interface SearchResults {
  tracks?: Track[];
  users?: Profile[];
}

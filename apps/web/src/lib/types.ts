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
  genre: string | null;
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

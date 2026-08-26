import { SITE_DESCRIPTION, SITE_NAME, SITE_URL } from './env';
import { toIsoDuration } from './format';
import { absoluteUrl, mediaUrl, routes } from './seo';
import type { Playlist, Profile, Track } from './types';

/**
 * سازنده‌های Schema.org (JSON-LD).
 * مرجع انتخاب نوع‌ها: MusicRecording برای تک آهنگ، MusicGroup برای هنرمند،
 * MusicPlaylist برای پلی‌لیست، CollectionPage برای صفحات دسته‌بندی.
 */

type JsonLd = Record<string, unknown>;

const ORGANIZATION_ID = `${SITE_URL}/#organization`;
const WEBSITE_ID = `${SITE_URL}/#website`;

export function organizationSchema(): JsonLd {
  return {
    '@type': 'Organization',
    '@id': ORGANIZATION_ID,
    name: SITE_NAME,
    url: SITE_URL,
    description: SITE_DESCRIPTION,
    logo: {
      '@type': 'ImageObject',
      url: absoluteUrl('/logo.png'),
    },
  };
}

/** WebSite + SearchAction — شرط لازم برای sitelinks searchbox گوگل */
export function websiteSchema(): JsonLd {
  return {
    '@type': 'WebSite',
    '@id': WEBSITE_ID,
    name: SITE_NAME,
    url: SITE_URL,
    inLanguage: 'fa-IR',
    description: SITE_DESCRIPTION,
    publisher: { '@id': ORGANIZATION_ID },
    potentialAction: {
      '@type': 'SearchAction',
      target: {
        '@type': 'EntryPoint',
        urlTemplate: `${SITE_URL}/search?q={search_term_string}`,
      },
      'query-input': 'required name=search_term_string',
    },
  };
}

export function breadcrumbSchema(
  items: { name: string; path: string }[],
): JsonLd {
  return {
    '@type': 'BreadcrumbList',
    itemListElement: items.map((item, index) => ({
      '@type': 'ListItem',
      position: index + 1,
      name: item.name,
      item: absoluteUrl(item.path),
    })),
  };
}

export function trackSchema(track: Track): JsonLd {
  const artist = track.user?.username;
  const url = absoluteUrl(routes.track(track.title, track.id));

  return {
    '@type': 'MusicRecording',
    '@id': `${url}#recording`,
    name: track.title,
    url,
    description: track.description || undefined,
    duration: toIsoDuration(track.duration),
    datePublished: track.createdAt,
    inLanguage: 'fa-IR',
    genre: track.genre || undefined,
    keywords: track.tags?.length ? track.tags.join('، ') : undefined,
    image: mediaUrl(track.coverUrl) || undefined,
    isFamilyFriendly: true,
    byArtist: artist
      ? {
          '@type': 'MusicGroup',
          name: artist,
          url: absoluteUrl(routes.artist(artist)),
        }
      : undefined,
    interactionStatistic: [
      {
        '@type': 'InteractionCounter',
        interactionType: 'https://schema.org/ListenAction',
        userInteractionCount: track.playCount ?? 0,
      },
      {
        '@type': 'InteractionCounter',
        interactionType: 'https://schema.org/LikeAction',
        userInteractionCount: track.likesCount ?? 0,
      },
      {
        '@type': 'InteractionCounter',
        interactionType: 'https://schema.org/CommentAction',
        userInteractionCount: track.commentsCount ?? 0,
      },
    ],
    audio: track.audioUrl
      ? {
          '@type': 'AudioObject',
          contentUrl: mediaUrl(track.audioUrl),
          encodingFormat: 'audio/mpeg',
          duration: toIsoDuration(track.duration),
          uploadDate: track.createdAt,
          name: track.title,
        }
      : undefined,
  };
}

export function artistSchema(profile: Profile, tracks: Track[]): JsonLd {
  const url = absoluteUrl(routes.artist(profile.username));

  return {
    '@type': 'MusicGroup',
    '@id': `${url}#artist`,
    name: profile.username,
    url,
    description: profile.bio || undefined,
    image: mediaUrl(profile.avatarUrl) || undefined,
    interactionStatistic: {
      '@type': 'InteractionCounter',
      interactionType: 'https://schema.org/FollowAction',
      userInteractionCount: profile.followersCount ?? 0,
    },
    track: tracks.slice(0, 20).map((track) => ({
      '@type': 'MusicRecording',
      name: track.title,
      url: absoluteUrl(routes.track(track.title, track.id)),
      duration: toIsoDuration(track.duration),
    })),
  };
}

/** ProfilePage — به گوگل می‌گوید این صفحه پروفایل یک شخص/گروه است. */
export function profilePageSchema(profile: Profile): JsonLd {
  const url = absoluteUrl(routes.artist(profile.username));
  return {
    '@type': 'ProfilePage',
    '@id': `${url}#profilepage`,
    url,
    dateCreated: profile.createdAt,
    mainEntity: { '@id': `${url}#artist` },
  };
}

export function playlistSchema(playlist: Playlist): JsonLd {
  const url = absoluteUrl(routes.playlist(playlist.title, playlist.id));
  const tracks = playlist.tracks ?? [];

  return {
    '@type': 'MusicPlaylist',
    '@id': `${url}#playlist`,
    name: playlist.title,
    url,
    description: playlist.description || undefined,
    numTracks: tracks.length,
    track: tracks.map((track) => ({
      '@type': 'MusicRecording',
      name: track.title,
      url: absoluteUrl(routes.track(track.title, track.id)),
      duration: toIsoDuration(track.duration),
      byArtist: track.user
        ? { '@type': 'MusicGroup', name: track.user.username }
        : undefined,
    })),
  };
}

/** صفحات فهرست (ژانر، جدیدترین‌ها، داغ‌ترین‌ها) */
export function collectionSchema(
  title: string,
  description: string,
  path: string,
  tracks: Track[],
): JsonLd {
  return {
    '@type': 'CollectionPage',
    '@id': `${absoluteUrl(path)}#collection`,
    name: title,
    description,
    url: absoluteUrl(path),
    inLanguage: 'fa-IR',
    isPartOf: { '@id': WEBSITE_ID },
    mainEntity: {
      '@type': 'ItemList',
      numberOfItems: tracks.length,
      itemListElement: tracks.map((track, index) => ({
        '@type': 'ListItem',
        position: index + 1,
        url: absoluteUrl(routes.track(track.title, track.id)),
        name: track.title,
      })),
    },
  };
}

/**
 * چند schema را در یک @graph می‌گذارد.
 * یک بلوک JSON-LD به‌ازای هر صفحه، ساده‌تر برای دیباگ و سبک‌تر برای خزنده.
 */
export function graph(...nodes: (JsonLd | null | undefined)[]): string {
  return JSON.stringify(
    { '@context': 'https://schema.org', '@graph': nodes.filter(Boolean) },
    // undefinedها حذف می‌شوند تا JSON تمیز بماند
    (_key, value) => (value === undefined ? undefined : value),
  );
}

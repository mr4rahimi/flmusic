import { getProfile } from '@/lib/api';
import { SITE_NAME } from '@/lib/env';
import { formatCount } from '@/lib/format';
import { OG_CONTENT_TYPE, OG_SIZE, ogCard } from '@/lib/og';
import { mediaUrl } from '@/lib/seo';

export const alt = 'پروفایل هنرمند';
export const size = OG_SIZE;
export const contentType = OG_CONTENT_TYPE;

export default async function Image({
  params,
}: {
  params: Promise<{ username: string }>;
}) {
  const { username: raw } = await params;
  const profile = await getProfile(decodeURIComponent(raw));

  return await ogCard({
    heading: profile?.username ?? SITE_NAME,
    subheading: profile
      ? `${formatCount(profile.tracksCount)} آهنگ · ${formatCount(profile.followersCount)} دنبال‌کننده`
      : undefined,
    imageUrl: mediaUrl(profile?.avatarUrl),
    rounded: true,
  });
}

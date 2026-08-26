import { getTrack } from '@/lib/api';
import { SITE_NAME } from '@/lib/env';
import { OG_CONTENT_TYPE, OG_SIZE, ogCard } from '@/lib/og';
import { extractId, mediaUrl } from '@/lib/seo';

export const alt = 'کاور آهنگ';
export const size = OG_SIZE;
export const contentType = OG_CONTENT_TYPE;

/** تصویر پیش‌نمایش اشتراک‌گذاری آهنگ (تلگرام، واتساپ، توییتر، فیسبوک) */
export default async function Image({ params }: { params: Promise<{ id: string }> }) {
  const { id: param } = await params;
  const trackId = extractId(param);
  const track = trackId ? await getTrack(trackId) : null;

  return await ogCard({
    heading: track?.title ?? SITE_NAME,
    subheading: track?.user?.username,
    imageUrl: mediaUrl(track?.coverUrl),
  });
}

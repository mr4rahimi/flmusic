import Image from 'next/image';
import { mediaUrl } from '@/lib/seo';

interface CoverProps {
  src: string | null | undefined;
  alt: string;
  sizes: string;
  priority?: boolean;
  className?: string;
}

/**
 * کاور آهنگ با نسبت ۱:۱ ثابت.
 * ابعاد ثابت جلوی CLS را می‌گیرد که یکی از سه Core Web Vital است.
 */
export function Cover({ src, alt, sizes, priority, className }: CoverProps) {
  const url = mediaUrl(src);

  return (
    <div
      className={`relative aspect-square overflow-hidden rounded-xl bg-neutral-800 ${className ?? ''}`}
    >
      {url ? (
        <Image
          src={url}
          alt={alt}
          fill
          sizes={sizes}
          priority={priority}
          className="object-cover"
        />
      ) : (
        <div
          className="flex h-full w-full items-center justify-center text-neutral-600"
          aria-hidden="true"
        >
          <svg viewBox="0 0 24 24" fill="currentColor" className="h-1/3 w-1/3">
            <path d="M12 3v10.55A4 4 0 1 0 14 17V7h4V3h-6Z" />
          </svg>
        </div>
      )}
    </div>
  );
}

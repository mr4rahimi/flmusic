import type { MetadataRoute } from 'next';
import { SITE_URL } from '@/lib/env';

/**
 * robots.txt
 * صفحات جستجو و مسیرهای خصوصی از ایندکس خارج می‌شوند تا بودجه‌ی خزش
 * صرف صفحات ارزشمند (آهنگ، هنرمند، ژانر) شود.
 */
export default function robots(): MetadataRoute.Robots {
  return {
    rules: [
      {
        userAgent: '*',
        allow: '/',
        disallow: ['/search', '/api/'],
      },
    ],
    sitemap: `${SITE_URL}/sitemap.xml`,
    host: SITE_URL,
  };
}

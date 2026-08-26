import type { NextConfig } from 'next';

/**
 * میزبان رسانه از NEXT_PUBLIC_MEDIA_URL خوانده می‌شود تا remotePatterns
 * با محیط لوکال و پروداکشن هماهنگ بماند.
 */
const mediaHost = (() => {
  try {
    const url = new URL(process.env.NEXT_PUBLIC_MEDIA_URL || 'http://localhost:3000');
    return { protocol: url.protocol.replace(':', ''), hostname: url.hostname, port: url.port };
  } catch {
    return { protocol: 'http', hostname: 'localhost', port: '3000' };
  }
})();

const nextConfig: NextConfig = {
  // خروجی خودکفا برای اجرا با PM2 روی سرور (بدون node_modules کامل)
  output: 'standalone',

  // فایل فونت در زمان اجرا با fs خوانده می‌شود، پس ردیاب وابستگی‌ها
  // خودش پیدایش نمی‌کند و باید صریح به خروجی standalone اضافه شود.
  outputFileTracingIncludes: {
    '/track/[id]/opengraph-image': ['./assets/fonts/**'],
    '/artist/[username]/opengraph-image': ['./assets/fonts/**'],
  },

  // هدر «X-Powered-By: Next.js» اطلاعات نسخه لو می‌دهد
  poweredByHeader: false,

  // اسلش انتهایی نداشته باشیم تا هر صفحه فقط یک URL معتبر داشته باشد
  trailingSlash: false,

  images: {
    remotePatterns: [
      {
        protocol: mediaHost.protocol as 'http' | 'https',
        hostname: mediaHost.hostname,
        port: mediaHost.port,
        pathname: '/uploads/**',
      },
    ],
    formats: ['image/avif', 'image/webp'],
    // کاورها تقریباً هرگز عوض نمی‌شوند؛ کش طولانی یعنی CPU کمتر روی سرور
    minimumCacheTTL: 60 * 60 * 24 * 7,
  },

  async headers() {
    return [
      {
        source: '/:path*',
        headers: [
          { key: 'X-Content-Type-Options', value: 'nosniff' },
          { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
          { key: 'X-Frame-Options', value: 'SAMEORIGIN' },
          {
            key: 'Permissions-Policy',
            value: 'camera=(), microphone=(), geolocation=()',
          },
        ],
      },
    ];
  },
};

export default nextConfig;

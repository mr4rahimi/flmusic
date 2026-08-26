/**
 * تنظیمات PM2 برای وب.
 *
 * نام پروسه عمداً از سرویس‌های موجود سرور جداست تا هیچ‌کدام
 * (music_api, music_meilisearch و سایت‌های دیگر) تحت تأثیر قرار نگیرند.
 */
module.exports = {
  apps: [
    {
      name: 'music_web',
      // مسیر current یک symlink است که به آخرین release اشاره می‌کند
      script: '/opt/music-platform/apps/web/current/server.js',
      cwd: '/opt/music-platform/apps/web/current',
      instances: 1,
      exec_mode: 'fork',
      max_memory_restart: '500M',
      env: {
        NODE_ENV: 'production',
        PORT: 3006,
        HOSTNAME: '127.0.0.1',
        // فچ‌های سمت سرور مستقیم به NestJS می‌روند و از CDN رد نمی‌شوند
        API_INTERNAL_URL: 'http://127.0.0.1:3000/api/v1',
      },
      error_file: '/var/log/pm2/music_web.error.log',
      out_file: '/var/log/pm2/music_web.out.log',
      merge_logs: true,
      time: true,
    },
  ],
};

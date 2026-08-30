import { readFile } from 'node:fs/promises';
import { join } from 'node:path';
import { ImageResponse } from 'next/og';
import { SITE_NAME } from './env';

export const OG_SIZE = { width: 1200, height: 630 };
export const OG_CONTENT_TYPE = 'image/png';

/**
 * فونت پیش‌فرض ImageResponse شکل‌دهی (shaping) خط فارسی را پشتیبانی نمی‌کند
 * و روی متن فارسی با خطای «substFormat: 3 is not yet supported» می‌شکند.
 * برای همین Vazirmatn را از assets/fonts می‌خوانیم و صریح پاس می‌دهیم.
 *
 * فایل‌ها بین درخواست‌ها در حافظه کش می‌شوند تا هر بار از دیسک خوانده نشوند.
 */
let fontCache: { name: string; data: Buffer; weight: 400 | 700; style: 'normal' }[] | null =
  null;

async function loadFonts() {
  if (fontCache) return fontCache;

  const dir = join(process.cwd(), 'assets', 'fonts');
  const [regular, bold] = await Promise.all([
    readFile(join(dir, 'Vazirmatn-Regular.ttf')),
    readFile(join(dir, 'Vazirmatn-Bold.ttf')),
  ]);

  fontCache = [
    { name: 'Vazirmatn', data: regular, weight: 400, style: 'normal' },
    { name: 'Vazirmatn', data: bold, weight: 700, style: 'normal' },
  ];
  return fontCache;
}

/**
 * موتور رندر ImageResponse (satori) الگوریتم bidi کامل ندارد و ترتیب
 * توکن‌های خط فارسی را معکوس می‌کند — «اف ال موزیک» به «موزیک ال اف» و
 * «دنبال‌کننده» به «کننده‌دنبال» تبدیل می‌شود.
 *
 * معکوس‌سازی‌اش منظم است (روی فاصله و نیم‌فاصله)، پس از قبل جبرانش می‌کنیم:
 * توکن‌ها را برعکس می‌چینیم تا خروجی نهایی درست دربیاید.
 *
 * فقط برای رشته‌هایی که حرف فارسی/عربی دارند اعمال می‌شود؛
 * عنوان‌های لاتین دست‌نخورده می‌مانند.
 */
function fixRtlOrder(text: string): string {
  if (!/[\u0600-\u06FF]/.test(text)) return text;

  // جداکننده‌ها را نگه می‌داریم تا فاصله و نیم‌فاصله سر جای خود بمانند
  return text.split(/([\s\u200c])/).reverse().join('');
}

interface OgCardProps {
  /** خط بزرگ — نام آهنگ، خواننده یا عنوان صفحه */
  heading: string;
  /** خط دوم — نام خواننده یا توضیح کوتاه */
  subheading?: string;
  /** تصویر مربعی سمت راست (کاور یا آواتار) */
  imageUrl?: string | null;
  /** آواتار گرد رندر شود یا کاور مربعی */
  rounded?: boolean;
}

/**
 * کارت پیش‌نمایش اشتراک‌گذاری.
 * ImageResponse فقط زیرمجموعه‌ای از CSS را می‌فهمد، پس همه‌چیز flex و inline style است.
 */
export async function ogCard({ heading, subheading, imageUrl, rounded }: OgCardProps) {
  const fonts = await loadFonts();

  return new ImageResponse(
    (
      <div
        style={{
          width: '100%',
          height: '100%',
          display: 'flex',
          alignItems: 'center',
          gap: 56,
          padding: 72,
          background: 'linear-gradient(135deg, #0a0a0a 0%, #14261f 100%)',
          color: '#ededed',
          fontFamily: 'Vazirmatn',
          // عمداً direction: 'rtl' ست نمی‌شود — موتور رندر satori خودش
          // خط فارسی را درست می‌چیند و با rtl ترتیب کلمات معکوس می‌شود.
        }}
      >
        {imageUrl ? (
          /* eslint-disable-next-line @next/next/no-img-element -- داخل ImageResponse فقط img پشتیبانی می‌شود */
          <img
            src={imageUrl}
            alt=""
            width={400}
            height={400}
            style={{ borderRadius: rounded ? 200 : 32, objectFit: 'cover' }}
          />
        ) : (
          <div
            style={{
              width: 400,
              height: 400,
              borderRadius: rounded ? 200 : 32,
              background: '#1c1c1c',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontSize: 180,
              color: '#3f3f3f',
            }}
          >
            ♪
          </div>
        )}

        <div style={{ display: 'flex', flexDirection: 'column', flex: 1 }}>
          <div style={{ fontSize: 30, color: '#34d399' }}>{fixRtlOrder(SITE_NAME)}</div>
          <div
            style={{
              fontSize: 62,
              fontWeight: 700,
              marginTop: 18,
              lineHeight: 1.25,
            }}
          >
            {fixRtlOrder(heading.slice(0, 70))}
          </div>
          {subheading && (
            /* هر بخش در span جداگانه، و چیدمان با row-reverse.
               اگر همه در یک رشته باشند، satori جای جداکننده‌ها را جابه‌جا
               می‌کند؛ این‌طور ترتیب را flexbox تعیین می‌کند نه bidi. */
            <div
              style={{
                display: 'flex',
                flexDirection: 'row-reverse',
                gap: 16,
                fontSize: 36,
                color: '#a3a3a3',
                marginTop: 18,
              }}
            >
              {subheading
                .slice(0, 60)
                .split('·')
                .map((part) => part.trim())
                .filter(Boolean)
                .flatMap((part, index) => [
                  ...(index > 0
                    ? [
                        <span key={`sep-${index}`} style={{ color: '#525252' }}>
                          ·
                        </span>,
                      ]
                    : []),
                  <span key={index}>{fixRtlOrder(part)}</span>,
                ])}
            </div>
          )}
        </div>
      </div>
    ),
    { ...OG_SIZE, fonts },
  );
}

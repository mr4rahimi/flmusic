/** ابزارهای نمایش — همه خروجی فارسی می‌دهند. */

const FA_DIGITS = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

export const toFaDigits = (value: string | number) =>
  String(value).replace(/\d/g, (d) => FA_DIGITS[Number(d)]);

/** ثانیه → «۳:۴۵» یا «۱:۰۲:۳۰» */
export function formatDuration(seconds: number | null | undefined): string {
  if (!seconds || seconds < 0) return '۰:۰۰';
  const s = Math.floor(seconds % 60);
  const m = Math.floor((seconds / 60) % 60);
  const h = Math.floor(seconds / 3600);
  const mm = h > 0 ? String(m).padStart(2, '0') : String(m);
  const parts = h > 0 ? [h, mm, String(s).padStart(2, '0')] : [mm, String(s).padStart(2, '0')];
  return toFaDigits(parts.join(':'));
}

/** ثانیه → مدت ISO 8601 برای schema.org (PT3M45S) */
export function toIsoDuration(seconds: number | null | undefined): string | undefined {
  if (!seconds || seconds <= 0) return undefined;
  const s = Math.floor(seconds % 60);
  const m = Math.floor((seconds / 60) % 60);
  const h = Math.floor(seconds / 3600);
  return `PT${h ? `${h}H` : ''}${m ? `${m}M` : ''}${s ? `${s}S` : ''}` || 'PT0S';
}

/** 12500 → «۱۲.۵ هزار» */
export function formatCount(value: number | null | undefined): string {
  const n = value ?? 0;
  if (n < 1000) return toFaDigits(n);
  if (n < 1_000_000) return `${toFaDigits((n / 1000).toFixed(n < 10_000 ? 1 : 0))} هزار`;
  return `${toFaDigits((n / 1_000_000).toFixed(1))} میلیون`;
}

const RELATIVE_UNITS: [limit: number, divisor: number, unit: string][] = [
  [60, 1, 'ثانیه'],
  [3600, 60, 'دقیقه'],
  [86400, 3600, 'ساعت'],
  [2592000, 86400, 'روز'],
  [31536000, 2592000, 'ماه'],
  [Infinity, 31536000, 'سال'],
];

/** تاریخ ISO → «۳ روز پیش» */
export function formatRelative(iso: string | null | undefined): string {
  if (!iso) return '';
  const diff = (Date.now() - new Date(iso).getTime()) / 1000;
  if (diff < 45) return 'همین حالا';
  for (const [limit, divisor, unit] of RELATIVE_UNITS) {
    if (diff < limit) return `${toFaDigits(Math.floor(diff / divisor))} ${unit} پیش`;
  }
  return '';
}

/** تاریخ ISO → «۱۴ مرداد ۱۴۰۵» */
export function formatDate(iso: string | null | undefined): string {
  if (!iso) return '';
  return new Intl.DateTimeFormat('fa-IR', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  }).format(new Date(iso));
}

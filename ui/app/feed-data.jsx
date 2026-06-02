// feed-data.jsx — icons, helpers, sample data, cover generator for فندق
// Exports to window: Icon, toFa, faNum, SONGS, TABS, coverFor, avatarFor

// ──────────────────────────────────────────────────────────
// Icons — stroke-based, currentColor. fill via `fill` prop.
// ──────────────────────────────────────────────────────────
const ICON_PATHS = {
  menu:    <><line x1="3.5" y1="7" x2="20.5" y2="7"/><line x1="3.5" y1="12" x2="20.5" y2="12"/><line x1="3.5" y1="17" x2="14" y2="17"/></>,
  sun:     <><circle cx="12" cy="12" r="4.2"/><line x1="12" y1="2.5" x2="12" y2="5"/><line x1="12" y1="19" x2="12" y2="21.5"/><line x1="2.5" y1="12" x2="5" y2="12"/><line x1="19" y1="12" x2="21.5" y2="12"/><line x1="5.4" y1="5.4" x2="7.1" y2="7.1"/><line x1="16.9" y1="16.9" x2="18.6" y2="18.6"/><line x1="5.4" y1="18.6" x2="7.1" y2="16.9"/><line x1="16.9" y1="7.1" x2="18.6" y2="5.4"/></>,
  moon:    <path d="M20 13.5A8 8 0 1 1 10.5 4a6.3 6.3 0 0 0 9.5 9.5z"/>,
  play:    <path d="M7 4.5l13 7.5-13 7.5z" />,
  pause:   <><rect x="6.5" y="5" width="3.6" height="14" rx="1.2"/><rect x="13.9" y="5" width="3.6" height="14" rx="1.2"/></>,
  heart:   <path d="M12 20.3l-1.4-1.27C5.4 14.36 2 11.28 2 7.5 2 4.42 4.42 2 7.5 2c1.74 0 3.41.81 4.5 2.09C13.09 2.81 14.76 2 16.5 2 19.58 2 22 4.42 22 7.5c0 3.78-3.4 6.86-8.6 11.54z"/>,
  comment: <path d="M21 11.5a8.38 8.38 0 0 1-8.5 8.5 8.5 8.5 0 0 1-3.8-.9L3 21l1.9-5.7A8.38 8.38 0 0 1 4 11.5 8.5 8.5 0 0 1 12.5 3 8.38 8.38 0 0 1 21 11.5z"/>,
  play2:   <><path d="M5 4.5l13 7.5-13 7.5z"/></>,
  headphones: <path d="M3.5 17v-5a8.5 8.5 0 0 1 17 0v5M3.5 16.5a2.5 2.5 0 0 1 5 0v2a2.5 2.5 0 0 1-5 0zm12 0a2.5 2.5 0 0 1 5 0v2a2.5 2.5 0 0 1-5 0z"/>,
  search:  <><circle cx="11" cy="11" r="7.2"/><line x1="20.5" y1="20.5" x2="16.2" y2="16.2"/></>,
  bell:    <path d="M18 8.5a6 6 0 0 0-12 0c0 7-2.5 8.5-2.5 8.5h17S18 15.5 18 8.5zM13.7 20.5a2 2 0 0 1-3.4 0"/>,
  plus:    <><line x1="12" y1="5.5" x2="12" y2="18.5"/><line x1="5.5" y1="12" x2="18.5" y2="12"/></>,
  user:    <><circle cx="12" cy="8" r="3.8"/><path d="M5 20c0-3.6 3.1-5.5 7-5.5s7 1.9 7 5.5"/></>,
  more:    <><circle cx="5" cy="12" r="1.6"/><circle cx="12" cy="12" r="1.6"/><circle cx="19" cy="12" r="1.6"/></>,
  bookmark:<path d="M6 3.5h12a1 1 0 0 1 1 1v16l-7-4.2L5 20.5v-16a1 1 0 0 1 1-1z"/>,
  share:   <path d="M14 8.5l5-5m0 0v4.5m0-4.5h-4.5M20 13.5v5a1.5 1.5 0 0 1-1.5 1.5h-13A1.5 1.5 0 0 1 4 18.5v-13A1.5 1.5 0 0 1 5.5 4H11"/>,
  verified:<path d="M12 2.5l2.2 1.7 2.8-.3 1.1 2.6 2.4 1.5-.7 2.7.7 2.7-2.4 1.5-1.1 2.6-2.8-.3L12 21.5l-2.2-1.7-2.8.3-1.1-2.6L3.5 16l.7-2.7L3.5 10.6 5.9 9.1 7 6.5l2.8.3z"/>,
  check:   <path d="M5 12.5l4.5 4.5L19 7"/>,
  upload:  <path d="M12 16V4m0 0L7.5 8.5M12 4l4.5 4.5M4 16v2.5A1.5 1.5 0 0 0 5.5 20h13a1.5 1.5 0 0 0 1.5-1.5V16"/>,
  mic:     <path d="M12 3a3 3 0 0 0-3 3v5a3 3 0 0 0 6 0V6a3 3 0 0 0-3-3zM5.5 11a6.5 6.5 0 0 0 13 0M12 17.5V21"/>,
  link:    <path d="M9 13.5l6-6M8 11l-2.3 2.3a3.5 3.5 0 0 0 5 5L13 16m-2-9l2.3-2.3a3.5 3.5 0 0 1 5 5L16 12"/>,
  close:   <><line x1="6" y1="6" x2="18" y2="18"/><line x1="18" y1="6" x2="6" y2="18"/></>,
  chevron: <path d="M15 6l-6 6 6 6"/>,
  flame:   <path d="M12 2.5c1 3 4 4.5 4 8a4 4 0 0 1-8 0c0-1 .3-1.8.8-2.5C9 9.5 9 8 8.5 7c2 .5 2.5-2.5 3.5-4.5z"/>,
  star:    <path d="M12 3l2.6 5.3 5.8.85-4.2 4.1 1 5.75L12 16.3l-5.2 2.7 1-5.75-4.2-4.1 5.8-.85z"/>,
  clock:   <><circle cx="12" cy="12" r="8.5"/><path d="M12 7.5V12l3 2"/></>,
};

function Icon({ name, size = 22, stroke = 2, fill = 'none', style = {}, ...rest }) {
  const p = ICON_PATHS[name];
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill={fill}
      stroke="currentColor" strokeWidth={stroke} strokeLinecap="round" strokeLinejoin="round"
      style={{ display: 'block', flexShrink: 0, ...style }} {...rest}>
      {p}
    </svg>
  );
}

// ──────────────────────────────────────────────────────────
// Persian digit + count helpers
// ──────────────────────────────────────────────────────────
const FA_DIGITS = ['۰','۱','۲','۳','۴','۵','۶','۷','۸','۹'];
function faNum(s) { return String(s).replace(/\d/g, d => FA_DIGITS[+d]); }
function toFa(n) {
  if (n < 1000) return faNum(n);
  if (n < 1000000) {
    const v = (n / 1000);
    const str = v >= 100 ? Math.round(v) : v.toFixed(1).replace(/\.0$/, '');
    return faNum(str) + 'هزار';
  }
  const v = (n / 1000000);
  return faNum(v.toFixed(1).replace(/\.0$/, '')) + 'م';
}

// ──────────────────────────────────────────────────────────
// Cover art — curated gradient palettes + abstract overlays
// ──────────────────────────────────────────────────────────
const PALETTES = [
  { a: '#6366f1', b: '#a855f7', c: '#312e81' },  // indigo→violet
  { a: '#fb7185', b: '#f59e0b', c: '#7f1d3a' },  // rose→amber
  { a: '#14b8a6', b: '#22d3ee', c: '#0f4c5c' },  // teal→cyan
  { a: '#f472b6', b: '#8b5cf6', c: '#581c87' },  // pink→purple
  { a: '#34d399', b: '#a3e635', c: '#14532d' },  // emerald→lime
  { a: '#60a5fa', b: '#6366f1', c: '#1e3a8a' },  // blue→indigo
  { a: '#fbbf24', b: '#f97316', c: '#7c2d12' },  // amber→orange
  { a: '#f43f5e', b: '#ec4899', c: '#831843' },  // red→pink
  { a: '#22d3ee', b: '#3b82f6', c: '#0c2d6b' },  // cyan→blue
  { a: '#c084fc', b: '#6366f1', c: '#3b0764' },  // lilac→indigo
];

// overlay style index → JSX of abstract shapes
function coverOverlay(kind, p) {
  const common = { position: 'absolute', pointerEvents: 'none' };
  if (kind === 0) return (
    <>
      <div style={{ ...common, inset: 0, background: `radial-gradient(120% 90% at 78% 18%, ${hexA(p.a,0.55)}, transparent 60%)` }} />
      <div style={{ ...common, width: '64%', height: '64%', right: '-16%', bottom: '-18%', borderRadius: '50%', border: `2px solid ${hexA('#ffffff',0.22)}` }} />
      <div style={{ ...common, width: '40%', height: '40%', right: '-4%', bottom: '-6%', borderRadius: '50%', border: `2px solid ${hexA('#ffffff',0.18)}` }} />
    </>
  );
  if (kind === 1) return (
    <>
      <div style={{ ...common, inset: 0, background: `repeating-linear-gradient(120deg, ${hexA('#ffffff',0.07)} 0 2px, transparent 2px 13px)` }} />
      <div style={{ ...common, width: '52%', height: '52%', left: '12%', top: '16%', borderRadius: '50%', background: hexA('#ffffff',0.16), filter: 'blur(2px)' }} />
    </>
  );
  if (kind === 2) return (
    <>
      <div style={{ ...common, inset: 0, background: `conic-gradient(from 210deg at 30% 80%, ${hexA('#ffffff',0.2)}, transparent 40%, ${hexA(p.c,0.5)} 80%, transparent)` }} />
    </>
  );
  if (kind === 3) return (
    <>
      <div style={{ ...common, width: '140%', height: '38%', left: '-20%', top: '34%', background: hexA('#ffffff',0.12), transform: 'rotate(-14deg)' }} />
      <div style={{ ...common, width: '140%', height: '14%', left: '-20%', top: '58%', background: hexA('#000000',0.12), transform: 'rotate(-14deg)' }} />
    </>
  );
  return (
    <>
      <div style={{ ...common, inset: 0, background: `radial-gradient(80% 80% at 20% 22%, ${hexA('#ffffff',0.28)}, transparent 55%)` }} />
      <div style={{ ...common, width: '50%', height: '50%', right: '8%', bottom: '8%', borderRadius: '38% 62% 55% 45% / 48% 40% 60% 52%', background: hexA(p.c,0.55) }} />
    </>
  );
}

function hexA(hex, a) {
  const n = parseInt(hex.slice(1), 16);
  return `rgba(${(n>>16)&255}, ${(n>>8)&255}, ${n&255}, ${a})`;
}

function coverFor(song) {
  const p = PALETTES[song.cov % PALETTES.length];
  return {
    background: `linear-gradient(145deg, ${p.a} 0%, ${p.b} 55%, ${p.c} 130%)`,
    overlay: coverOverlay(song.ov, p),
    palette: p,
  };
}

function avatarFor(author) {
  const p = PALETTES[author.av % PALETTES.length];
  return `linear-gradient(140deg, ${p.a}, ${p.b})`;
}

// ──────────────────────────────────────────────────────────
// Sample data
// ──────────────────────────────────────────────────────────
const SONGS = [
  { id: 1, author: { name: 'نگار رستمی', handle: 'negar.music', av: 0, verified: true },
    title: 'شب‌های بی‌ستاره', artist: 'نگار رستمی', genre: 'پاپ آلترناتیو',
    cov: 0, ov: 0, date: '۲ ساعت پیش', dur: 213, likes: 12400, comments: 842, plays: 98200 },
  { id: 2, author: { name: 'آرش کمانگیر', handle: 'arash.beats', av: 6, verified: false },
    title: 'کوچه‌های بارانی', artist: 'آرش کمانگیر', genre: 'لو-فای / بیت',
    cov: 6, ov: 3, date: 'دیروز', dur: 184, likes: 5210, comments: 318, plays: 41300 },
  { id: 3, author: { name: 'استودیو مهتاب', handle: 'mahtab.studio', av: 2, verified: true },
    title: 'دریا، نمک، تو', artist: 'سها و باند', genre: 'ایندی راک',
    cov: 2, ov: 2, date: '۱ روز پیش', dur: 247, likes: 23800, comments: 1540, plays: 187000 },
  { id: 4, author: { name: 'مانی صبوری', handle: 'mani.s', av: 9, verified: false },
    title: 'خاطرات نیمه‌کاره', artist: 'مانی صبوری', genre: 'الکترونیک',
    cov: 9, ov: 4, date: '۳ روز پیش', dur: 198, likes: 3120, comments: 145, plays: 22700 },
  { id: 5, author: { name: 'گروه پرنده', handle: 'parandeh', av: 4, verified: true },
    title: 'پرواز در مه', artist: 'گروه پرنده', genre: 'پست‌راک',
    cov: 4, ov: 0, date: '۴ روز پیش', dur: 305, likes: 41200, comments: 2890, plays: 512000 },
  { id: 6, author: { name: 'دل‌آرا توکلی', handle: 'delara.t', av: 7, verified: false },
    title: 'قرار نبود', artist: 'دل‌آرا توکلی', genre: 'پاپ سنتی',
    cov: 7, ov: 1, date: '۵ روز پیش', dur: 226, likes: 8900, comments: 612, plays: 73400 },
  { id: 7, author: { name: 'رِوِرب کالکتیو', handle: 'reverb.co', av: 3, verified: true },
    title: 'نئون و خاکستر', artist: 'رِوِرب کالکتیو', genre: 'سینث‌ویو',
    cov: 3, ov: 2, date: '۱ هفته پیش', dur: 271, likes: 17600, comments: 980, plays: 154000 },
  { id: 8, author: { name: 'سامان آذر', handle: 'saman.azar', av: 1, verified: false },
    title: 'جاده‌ی شمال', artist: 'سامان آذر', genre: 'فولک',
    cov: 1, ov: 3, date: '۱ هفته پیش', dur: 209, likes: 6400, comments: 401, plays: 58100 },
];

const TABS = [
  { key: 'popular', label: 'محبوب‌ها', icon: 'star' },
  { key: 'following', label: 'دنبال‌شده‌ها', icon: 'headphones' },
  { key: 'newest', label: 'جدیدترین', icon: 'clock' },
];

// ordering per tab
function orderFor(key) {
  const a = [...SONGS];
  if (key === 'popular') return a.sort((x, y) => y.plays - x.plays);
  if (key === 'newest') return [1,2,4,6,3,8,5,7].map(id => SONGS.find(s => s.id === id));
  return [3,5,7,1,6,2,8,4].map(id => SONGS.find(s => s.id === id)); // following
}

Object.assign(window, { Icon, toFa, faNum, SONGS, TABS, coverFor, avatarFor, orderFor });

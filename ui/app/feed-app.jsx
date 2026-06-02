// feed-app.jsx — فندق feed screen. Depends on feed-data.jsx (window globals).
const { useState, useEffect, useRef, useCallback } = React;

// ── small animated equalizer (now-playing indicator) ──────────
function Equalizer({ size = 16, color = '#fff', playing = true }) {
  const bars = [0, 1, 2, 3];
  return (
    <div style={{ display: 'flex', alignItems: 'flex-end', gap: 2, height: size, width: size }}>
      {bars.map(i => (
        <span key={i} style={{
          flex: 1, background: color, borderRadius: 2,
          height: '40%',
          animation: playing ? `eqbar 900ms ease-in-out ${i * 130}ms infinite` : 'none',
        }} />
      ))}
    </div>
  );
}

// ── header ────────────────────────────────────────────────────
function Header({ dark, onToggleTheme, onMenu }) {
  return (
    <header className="fx-header">
      <button className="fx-iconbtn" onClick={onMenu} aria-label="منو">
        <Icon name="menu" size={23} stroke={2.1} />
      </button>

      <div className="fx-logo">
        <span className="fx-logo-mark" aria-hidden="true">
          <span className="fx-seed" />
        </span>
        <span className="fx-logo-word">فندق</span>
      </div>

      <button className="fx-iconbtn fx-theme" onClick={onToggleTheme} aria-label="تغییر حالت روز و شب">
        <span className="fx-theme-swap" data-dark={dark ? '1' : '0'}>
          <Icon name="sun" size={22} stroke={2} />
          <Icon name="moon" size={21} stroke={2} />
        </span>
      </button>
    </header>
  );
}

// ── tabs ────────────────────────────────────────────────────
function Tabs({ active, onChange }) {
  const ref = useRef(null);
  const [pill, setPill] = useState({ width: 0, x: 0 });
  useEffect(() => {
    const el = ref.current?.querySelector(`[data-tab="${active}"]`);
    if (el) setPill({ width: el.offsetWidth, x: el.offsetLeft });
  }, [active]);
  return (
    <div className="fx-tabs" ref={ref}>
      <span className="fx-tabs-pill" style={{ width: pill.width, transform: `translateX(${pill.x}px)` }} />
      {TABS.map(t => (
        <button key={t.key} data-tab={t.key}
          className={'fx-tab' + (active === t.key ? ' is-active' : '')}
          onClick={() => onChange(t.key)}>
          <Icon name={t.icon} size={17} stroke={2.1} />
          <span>{t.label}</span>
        </button>
      ))}
    </div>
  );
}

// ── song card ────────────────────────────────────────────────
function SongCard({ song, isCurrent, isPlaying, progress, onPlay, index }) {
  const cover = coverFor(song);
  const [liked, setLiked] = useState(song.id % 5 === 0);
  const [likes, setLikes] = useState(song.likes);
  const [pop, setPop] = useState(false);
  const [saved, setSaved] = useState(false);

  const toggleLike = () => {
    setLiked(v => {
      const nv = !v;
      setLikes(c => c + (nv ? 1 : -1));
      if (nv) { setPop(true); setTimeout(() => setPop(false), 620); }
      return nv;
    });
  };

  return (
    <article className="fx-card" style={{ '--d': `${index * 55}ms` }}>
      {/* cover */}
      <div className="fx-cover" style={{ background: cover.background }} onDoubleClick={toggleLike}>
        {cover.overlay}
        <div className="fx-cover-scrim" />

        {/* genre chip */}
        <span className="fx-chip fx-chip-genre">{song.genre}</span>
        {/* duration chip */}
        <span className="fx-chip fx-chip-dur">
          {faNum(Math.floor(song.dur / 60))}:{faNum(String(song.dur % 60).padStart(2, '0'))}
        </span>

        {/* big play */}
        <button className={'fx-play' + (isCurrent && isPlaying ? ' is-playing' : '')}
          onClick={() => onPlay(song)} aria-label={isCurrent && isPlaying ? 'مکث' : 'پخش'}>
          {isCurrent && isPlaying
            ? <Equalizer size={20} color="#fff" />
            : <Icon name="play" size={26} fill="#fff" stroke={0} style={{ marginRight: -3 }} />}
        </button>

        {/* heart burst on double-tap */}
        <div className={'fx-burst' + (pop ? ' is-on' : '')}><Icon name="heart" size={86} fill="#fff" stroke={0} /></div>

        {/* progress for current track */}
        {isCurrent && (
          <div className="fx-cover-prog"><span style={{ width: `${progress * 100}%` }} /></div>
        )}
      </div>

      {/* body */}
      <div className="fx-card-body">
        <div className="fx-meta">
          <div className="fx-avatar" style={{ background: avatarFor(song.author) }}>
            {song.author.name.trim()[0]}
          </div>
          <div className="fx-meta-txt">
            <div className="fx-author">
              <span className="fx-author-name">{song.author.name}</span>
              {song.author.verified && <span className="fx-verified"><Icon name="check" size={9} stroke={3.4} /></span>}
            </div>
            <div className="fx-date">{song.date}</div>
          </div>
          <button className="fx-followbtn">دنبال کردن</button>
          <button className="fx-ghostbtn" aria-label="بیشتر"><Icon name="more" size={20} stroke={2} /></button>
        </div>

        <h3 className="fx-title">{song.title}</h3>

        {/* actions */}
        <div className="fx-actions">
          <button className={'fx-act fx-like' + (liked ? ' is-liked' : '') + (pop ? ' is-pop' : '')} onClick={toggleLike}>
            <Icon name="heart" size={21} fill={liked ? 'currentColor' : 'none'} stroke={2} />
            <span>{toFa(likes)}</span>
          </button>
          <button className="fx-act">
            <Icon name="comment" size={21} stroke={2} />
            <span>{toFa(song.comments)}</span>
          </button>
          <button className="fx-act fx-plays">
            <Icon name="headphones" size={21} stroke={2} />
            <span>{toFa(song.plays)}</span>
          </button>
          <span className="fx-spacer" />
          <button className={'fx-ghostbtn' + (saved ? ' is-on' : '')} onClick={() => setSaved(s => !s)} aria-label="ذخیره">
            <Icon name="bookmark" size={20} fill={saved ? 'currentColor' : 'none'} stroke={2} />
          </button>
          <button className="fx-ghostbtn" aria-label="هم‌رسانی"><Icon name="share" size={20} stroke={2} /></button>
        </div>
      </div>
    </article>
  );
}

// ── mini player ──────────────────────────────────────────────
function MiniPlayer({ track, playing, progress, onToggle, onClose }) {
  if (!track) return null;
  const cover = coverFor(track);
  return (
    <div className="fx-player">
      <div className="fx-player-prog"><span style={{ width: `${progress * 100}%` }} /></div>
      <div className="fx-player-row">
        <div className="fx-player-cover" style={{ background: cover.background }}>
          <Equalizer size={14} color="#fff" playing={playing} />
        </div>
        <div className="fx-player-txt">
          <div className="fx-player-title">{track.title}</div>
          <div className="fx-player-artist">{track.artist}</div>
        </div>
        <button className="fx-player-btn" onClick={onToggle} aria-label={playing ? 'مکث' : 'پخش'}>
          <Icon name={playing ? 'pause' : 'play'} size={22} fill="currentColor" stroke={0}
            style={{ marginRight: playing ? 0 : -2 }} />
        </button>
        <button className="fx-player-close" onClick={onClose} aria-label="بستن"><Icon name="close" size={18} stroke={2.2} /></button>
      </div>
    </div>
  );
}

// ── bottom nav ───────────────────────────────────────────────
const NAV = [
  { key: 'feed', label: 'فید', icon: 'play2' },
  { key: 'search', label: 'جستجو', icon: 'search' },
  { key: 'add', label: '', icon: 'plus', fab: true },
  { key: 'alerts', label: 'اعلان‌ها', icon: 'bell', badge: 3 },
  { key: 'profile', label: 'پروفایل', icon: 'user' },
];
function BottomNav({ active, onNav }) {
  return (
    <nav className="fx-nav">
      {NAV.map(n => n.fab ? (
        <button key={n.key} className="fx-fab" onClick={() => onNav('add')} aria-label="ثبت آهنگ جدید">
          <Icon name="plus" size={28} stroke={2.6} />
        </button>
      ) : (
        <button key={n.key} className={'fx-navitem' + (active === n.key ? ' is-active' : '')} onClick={() => onNav(n.key)}>
          <span className="fx-navicon">
            <Icon name={n.icon} size={24} stroke={2}
              fill={n.key === 'feed' && active === 'feed' ? 'currentColor' : 'none'} />
            {n.badge && <span className="fx-navbadge">{faNum(n.badge)}</span>}
          </span>
          <span className="fx-navlabel">{n.label}</span>
        </button>
      ))}
    </nav>
  );
}

// ── side drawer (hamburger) ─────────────────────────────────
const DRAWER_ITEMS = [
  { icon: 'user', label: 'حساب کاربری من' },
  { icon: 'headphones', label: 'آهنگ‌های من' },
  { icon: 'bookmark', label: 'ذخیره‌شده‌ها' },
  { icon: 'flame', label: 'پرطرفدارها' },
  { icon: 'bell', label: 'تنظیمات اعلان' },
];
function Drawer({ open, onClose, dark, onToggleTheme }) {
  return (
    <div className={'fx-drawer-wrap' + (open ? ' is-open' : '')}>
      <div className="fx-scrim" onClick={onClose} />
      <aside className="fx-drawer">
        <div className="fx-drawer-head">
          <div className="fx-drawer-avatar">ش</div>
          <div>
            <div className="fx-drawer-name">شهاب کریمی</div>
            <div className="fx-drawer-handle">@shahab.k</div>
          </div>
          <button className="fx-ghostbtn" onClick={onClose} aria-label="بستن"><Icon name="close" size={20} stroke={2.2} /></button>
        </div>
        <div className="fx-drawer-stats">
          <div><b>۲۴</b><span>آهنگ</span></div>
          <div><b>۱۸٬۲۰۰</b><span>دنبال‌کننده</span></div>
          <div><b>۳۱۲</b><span>دنبال‌شده</span></div>
        </div>
        <div className="fx-drawer-list">
          {DRAWER_ITEMS.map(it => (
            <button key={it.label} className="fx-drawer-item">
              <Icon name={it.icon} size={21} stroke={2} />
              <span>{it.label}</span>
              <Icon name="chevron" size={18} stroke={2} className="fx-drawer-chev" />
            </button>
          ))}
        </div>
        <button className="fx-drawer-theme" onClick={onToggleTheme}>
          <Icon name={dark ? 'sun' : 'moon'} size={20} stroke={2} />
          <span>{dark ? 'حالت روز' : 'حالت شب'}</span>
        </button>
      </aside>
    </div>
  );
}

// ── upload sheet (+) ─────────────────────────────────────────
const UPLOAD_OPTS = [
  { icon: 'upload', label: 'آپلود فایل صوتی', sub: 'MP3، WAV یا FLAC' },
  { icon: 'mic', label: 'ضبط مستقیم', sub: 'همین حالا ضبط کن' },
  { icon: 'link', label: 'از طریق لینک', sub: 'لینک فایل صوتی را بچسبان' },
];
function UploadSheet({ open, onClose }) {
  return (
    <div className={'fx-sheet-wrap' + (open ? ' is-open' : '')}>
      <div className="fx-scrim" onClick={onClose} />
      <div className="fx-sheet">
        <div className="fx-sheet-grip" />
        <h3 className="fx-sheet-title">ثبت آهنگ جدید</h3>
        <p className="fx-sheet-sub">آهنگت رو با دنبال‌کننده‌هات به اشتراک بذار</p>
        <div className="fx-sheet-opts">
          {UPLOAD_OPTS.map(o => (
            <button key={o.label} className="fx-sheet-opt">
              <span className="fx-sheet-ico"><Icon name={o.icon} size={23} stroke={2} /></span>
              <span className="fx-sheet-txt">
                <span className="fx-sheet-opt-label">{o.label}</span>
                <span className="fx-sheet-opt-sub">{o.sub}</span>
              </span>
              <Icon name="chevron" size={18} stroke={2} className="fx-drawer-chev" />
            </button>
          ))}
        </div>
        <button className="fx-sheet-cancel" onClick={onClose}>انصراف</button>
      </div>
    </div>
  );
}

// ── App ──────────────────────────────────────────────────────
function FeedApp({ t, setTweak }) {
  const dark = t.dark;
  const [tab, setTab] = useState('popular');
  const [nav, setNav] = useState('feed');
  const [drawer, setDrawer] = useState(false);
  const [sheet, setSheet] = useState(false);
  const [track, setTrack] = useState(null);
  const [playing, setPlaying] = useState(false);
  const [progress, setProgress] = useState(0);
  const scrollRef = useRef(null);

  // playback tick
  useEffect(() => {
    if (!playing || !track) return;
    const iv = setInterval(() => {
      setProgress(p => {
        const np = p + 1 / (track.dur * 4); // 4 ticks/sec
        if (np >= 1) { setPlaying(false); return 0; }
        return np;
      });
    }, 250);
    return () => clearInterval(iv);
  }, [playing, track]);

  const onPlay = useCallback((song) => {
    setTrack(prev => {
      if (prev && prev.id === song.id) { setPlaying(p => !p); return prev; }
      setProgress(0); setPlaying(true); return song;
    });
  }, []);

  const onNav = (key) => {
    if (key === 'add') { setSheet(true); return; }
    setNav(key);
  };

  const list = orderFor(tab);

  useEffect(() => { if (scrollRef.current) scrollRef.current.scrollTop = 0; }, [tab]);

  return (
    <div className="fx-root" data-theme={dark ? 'dark' : 'light'} dir="rtl" lang="fa">
      <Header dark={dark} onToggleTheme={() => setTweak('dark', !dark)} onMenu={() => setDrawer(true)} />
      <Tabs active={tab} onChange={setTab} />

      <main className="fx-feed" ref={scrollRef}>
        <div className="fx-feed-inner" key={tab}>
          {list.map((song, i) => (
            <SongCard key={song.id} song={song} index={i}
              isCurrent={track?.id === song.id} isPlaying={playing} progress={track?.id === song.id ? progress : 0}
              onPlay={onPlay} />
          ))}
          <div className="fx-end">— به انتهای فید رسیدی —</div>
        </div>
      </main>

      <MiniPlayer track={track} playing={playing} progress={progress}
        onToggle={() => setPlaying(p => !p)} onClose={() => { setTrack(null); setPlaying(false); setProgress(0); }} />

      <BottomNav active={nav} onNav={onNav} />

      <Drawer open={drawer} onClose={() => setDrawer(false)} dark={dark} onToggleTheme={() => setTweak('dark', !dark)} />
      <UploadSheet open={sheet} onClose={() => setSheet(false)} />
    </div>
  );
}

Object.assign(window, { FeedApp });

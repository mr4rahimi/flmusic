'use client';

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
} from 'react';
import { mediaUrl } from '@/lib/seo';
import type { Track } from '@/lib/types';

interface PlayerState {
  current: Track | null;
  isPlaying: boolean;
  position: number;
  duration: number;
  play: (track: Track) => void;
  toggle: () => void;
  seek: (seconds: number) => void;
  isCurrent: (trackId: string) => boolean;
}

const PlayerContext = createContext<PlayerState | null>(null);

export function usePlayer(): PlayerState {
  const context = useContext(PlayerContext);
  if (!context) throw new Error('usePlayer باید داخل PlayerProvider باشد');
  return context;
}

/**
 * یک تگ <audio> برای کل سایت. با ناوبری بین صفحات (App Router)
 * پخش قطع نمی‌شود چون provider در layout ریشه زندگی می‌کند.
 */
export function PlayerProvider({ children }: { children: React.ReactNode }) {
  const audioRef = useRef<HTMLAudioElement | null>(null);
  const [current, setCurrent] = useState<Track | null>(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [position, setPosition] = useState(0);
  const [duration, setDuration] = useState(0);

  const play = useCallback(
    (track: Track) => {
      const audio = audioRef.current;
      if (!audio) return;

      if (current?.id === track.id) {
        void audio.play();
        return;
      }

      const source = mediaUrl(track.audioUrl);
      if (!source) return;

      setCurrent(track);
      setPosition(0);
      setDuration(track.duration ?? 0);
      audio.src = source;
      void audio.play().catch(() => setIsPlaying(false));
    },
    [current],
  );

  const toggle = useCallback(() => {
    const audio = audioRef.current;
    if (!audio || !current) return;
    if (audio.paused) void audio.play();
    else audio.pause();
  }, [current]);

  const seek = useCallback((seconds: number) => {
    const audio = audioRef.current;
    if (!audio) return;
    audio.currentTime = seconds;
    setPosition(seconds);
  }, []);

  const isCurrent = useCallback(
    (trackId: string) => current?.id === trackId,
    [current],
  );

  // متادیتای Media Session تا کنترل‌های سیستم‌عامل و قفل‌صفحه درست نشان داده شوند
  useEffect(() => {
    if (!current || typeof navigator === 'undefined' || !('mediaSession' in navigator)) {
      return;
    }
    const artwork = mediaUrl(current.coverUrl);
    navigator.mediaSession.metadata = new MediaMetadata({
      title: current.title,
      artist: current.user?.username ?? '',
      artwork: artwork ? [{ src: artwork, sizes: '512x512' }] : [],
    });
  }, [current]);

  const value = useMemo<PlayerState>(
    () => ({ current, isPlaying, position, duration, play, toggle, seek, isCurrent }),
    [current, isPlaying, position, duration, play, toggle, seek, isCurrent],
  );

  return (
    <PlayerContext.Provider value={value}>
      {children}
      <audio
        ref={audioRef}
        preload="none"
        onPlay={() => setIsPlaying(true)}
        onPause={() => setIsPlaying(false)}
        onEnded={() => setIsPlaying(false)}
        onTimeUpdate={(event) => setPosition(event.currentTarget.currentTime)}
        onLoadedMetadata={(event) => setDuration(event.currentTarget.duration)}
      />
    </PlayerContext.Provider>
  );
}

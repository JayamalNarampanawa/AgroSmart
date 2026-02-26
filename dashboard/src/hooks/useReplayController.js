import { useEffect, useMemo, useState } from "react";

const clampIndex = (idx, last) => {
  if (last < 0) return 0;
  if (idx < 0) return 0;
  if (idx > last) return last;
  return idx;
};

const safeParse = (raw, fallback) => {
  try {
    const parsed = JSON.parse(raw);
    return parsed ?? fallback;
  } catch (_) {
    return fallback;
  }
};

export default function useReplayController({
  buffer = [],
  liveData = null,
  initialMode = "LIVE",
  initialSpeed = 1,
  persistKey = "agrosmart-replay",
  loop = false,
} = {}) {
  const persisted = useMemo(() => {
    if (typeof window === "undefined") return null;
    const raw = window.localStorage.getItem(persistKey);
    return raw ? safeParse(raw, null) : null;
  }, [persistKey]);

  const [mode, setMode] = useState(persisted?.mode || initialMode);
  const [replayIndex, setReplayIndex] = useState(() => {
    const last = buffer.length - 1;
    return last >= 0 ? last : 0;
  });
  const [isPlaying, setIsPlaying] = useState(false);
  const [speed, setSpeed] = useState(persisted?.speed || initialSpeed);

  useEffect(() => {
    if (typeof window === "undefined") return undefined;
    window.localStorage.setItem(persistKey, JSON.stringify({ mode, speed }));
    return undefined;
  }, [mode, speed, persistKey]);

  useEffect(() => {
    setReplayIndex((idx) => clampIndex(idx, buffer.length - 1));
    if (mode === "LIVE") {
      setReplayIndex(buffer.length ? buffer.length - 1 : 0);
    }
  }, [buffer.length, mode]);

  useEffect(() => {
    if (mode !== "REPLAY" || !isPlaying || buffer.length === 0)
      return undefined;
    const intervalMs = Math.max(250, 1000 / Math.max(speed, 0.25));
    const id = setInterval(() => {
      setReplayIndex((idx) => {
        const last = buffer.length - 1;
        if (last < 0) return 0;
        const next = idx + 1;
        if (next > last) {
          if (loop) return 0;
          setIsPlaying(false);
          return last;
        }
        return next;
      });
    }, intervalMs);
    return () => clearInterval(id);
  }, [mode, isPlaying, speed, buffer.length, loop]);

  const goLive = () => {
    setMode("LIVE");
    setIsPlaying(false);
    setReplayIndex(buffer.length ? buffer.length - 1 : 0);
  };

  const enterReplay = () => {
    if (buffer.length === 0) return;
    setMode("REPLAY");
  };

  const seek = (idx) => {
    if (buffer.length === 0) return;
    enterReplay();
    setReplayIndex(clampIndex(idx, buffer.length - 1));
  };

  const step = (delta) => {
    if (buffer.length === 0) return;
    enterReplay();
    setReplayIndex((idx) => clampIndex(idx + delta, buffer.length - 1));
  };

  const togglePlay = () => {
    if (mode !== "REPLAY") {
      enterReplay();
      setIsPlaying(true);
      return;
    }
    if (buffer.length === 0) return;
    setIsPlaying((v) => !v);
  };

  const currentSnapshot = useMemo(() => {
    if (!buffer.length) return null;
    return buffer[clampIndex(replayIndex, buffer.length - 1)];
  }, [buffer, replayIndex]);

  const effectiveData = useMemo(() => {
    if (mode === "REPLAY" && currentSnapshot) return currentSnapshot;
    if (liveData) return liveData;
    if (buffer.length) return buffer[buffer.length - 1];
    return null;
  }, [mode, currentSnapshot, liveData, buffer]);

  const atEnd =
    mode === "REPLAY" && buffer.length > 0 && replayIndex >= buffer.length - 1;

  return {
    mode,
    setMode,
    replayIndex,
    setReplayIndex,
    isPlaying,
    setIsPlaying,
    speed,
    setSpeed,
    togglePlay,
    seek,
    step,
    goLive,
    enterReplay,
    effectiveData,
    currentSnapshot,
    atEnd,
  };
}

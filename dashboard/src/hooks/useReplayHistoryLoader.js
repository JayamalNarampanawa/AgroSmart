import { useCallback, useState } from "react";
import { get, limitToLast, orderByChild, query, ref } from "firebase/database";
import { database } from "../firebase";

// Numbers: always return a finite number, otherwise fallback (default 0)
const toNumber = (v, fallback = 0) => {
  const n = Number(v);
  return Number.isFinite(n) ? n : fallback;
};

// Booleans: robust parsing for true/false variants
const toBool = (v, fallback = false) => {
  if (typeof v === "boolean") return v;
  if (typeof v === "number") return v === 1;
  if (typeof v === "string") {
    const s = v.trim().toLowerCase();
    if (["1", "on", "true", "yes"].includes(s)) return true;
    if (["0", "off", "false", "no"].includes(s)) return false;
  }
  return fallback;
};

export default function useReplayHistoryLoader({ limit = 900 } = {}) {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null); // string or null
  const [loadedCount, setLoadedCount] = useState(0);

  /**
   * Loads last N history records from:
   * /AgroSmart/analytics/timeseries
   *
   * Records are push-id keyed and contain a child "timestamp" (ms).
   * We query ordered by "timestamp" and then sort to be safe.
   */
  const loadHistory = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      const baseRef = ref(database, "/AgroSmart/analytics/timeseries");

      // IMPORTANT: Your DB uses "timestamp" (not "ts")
      const q = query(baseRef, orderByChild("timestamp"), limitToLast(limit));
      const snap = await get(q);

      const val = snap.val();
      if (!val || typeof val !== "object") {
        setLoadedCount(0);
        return [];
      }

      const entries = Object.entries(val);

      // Carry-forward light level for records that don't have it
      let lastLight = 0;

      const snapshots = entries
        .map(([key, entry]) => {
          if (!entry || typeof entry !== "object") return null;

          const ts = Number(entry.timestamp);
          if (!Number.isFinite(ts)) return null; // timestamp must be finite

          // Default all numeric fields to 0 (never null/NaN)
          const temperature = toNumber(entry.temperature, 0);
          const humidity = toNumber(entry.humidity, 0);
          const soilMoisture = toNumber(entry.soilMoisture, 0);

          const lightCandidate = Number(entry.lightLevel);
          const lightLevel = Number.isFinite(lightCandidate)
            ? lightCandidate
            : lastLight || 0;

          lastLight = lightLevel;

          // pumpStatus is the truth source for irrigation
          const irrigationOn = toBool(entry.pumpStatus, false);
          const irrigation = irrigationOn ? "ON" : "OFF";

          return {
            ts,
            temperature,
            humidity,
            soilMoisture,
            lightLevel,
            irrigationStatus: irrigationOn,
            pumpStatus: irrigationOn,
            __raw: {
              Temperature: temperature,
              Humidity: humidity,
              SoilMoisture: soilMoisture,
              LightLevel: lightLevel,
              Irrigation: irrigation,
            },
            __key: key,
          };
        })
        .filter(Boolean)
        .sort((a, b) => a.ts - b.ts); // stable order

      setLoadedCount(snapshots.length);
      return snapshots;
    } catch (e) {
      console.error("[ReplayHistory] load failed", e);
      setError(e?.message || String(e));
      setLoadedCount(0);
      return [];
    } finally {
      setLoading(false);
    }
  }, [limit]);

  return { loadHistory, loading, error, loadedCount };
}

import { useEffect, useRef, useState } from "react";
import { onValue, ref } from "firebase/database";
import { database, authReady } from "../firebase";
import { calibration } from "./calibration";

const DEFAULT_DATA = {
  temperature: 24,
  humidity: 60,
  soilMoisture: 48,
  lightLevel: 40,
  irrigationStatus: false,
};

const toNumber = (v, fallback) => {
  const n = Number(v);
  return Number.isFinite(n) ? n : fallback;
};

const getFirstNumber = (payload, keys, fallback) => {
  for (const key of keys) {
    if (payload[key] !== undefined && payload[key] !== null) {
      return toNumber(payload[key], fallback);
    }
  }
  return fallback;
};

const parseIrrigationStatus = (payload = {}) => {
  const candidates = [
    payload.irrigationStatus,
    payload.irrigation,
    payload.Irrigation,
    payload.pumpStatus,
    payload.pump,
    payload.relay,
    payload.motor,
  ];
  const val = candidates.find((v) => v !== undefined && v !== null);
  if (typeof val === "boolean") return val;
  if (typeof val === "number") return val === 1;
  if (typeof val === "string") {
    const s = val.trim().toLowerCase();
    return s === "on" || s === "1" || s === "true";
  }
  return false;
};

const clamp01 = (v) => Math.max(0, Math.min(1, v));

const hysteresisSoil = (wetness, prev) => {
  const margin = calibration.soil.hysteresis ?? 0.05;
  const dryThresh = 0.35;
  const wetThresh = 0.75;
  if (prev === "Dry" && wetness < dryThresh + margin) return "Dry";
  if (prev === "Wet" && wetness > wetThresh - margin) return "Wet";
  if (wetness < dryThresh) return "Dry";
  if (wetness > wetThresh) return "Wet";
  return "Optimal";
};

const hysteresisLight = (brightness, prev) => {
  const low = 0.35;
  const high = 0.8;
  const margin = calibration.light.hysteresis ?? 0.05;
  if (prev === "Low" && brightness < low + margin) return "Low";
  if (prev === "High" && brightness > high - margin) return "High";
  if (brightness < low) return "Low";
  if (brightness > high) return "High";
  return "Normal";
};

const hysteresisTemp = (temp, prev) => {
  const { coolMax, normalMax, hotMin } = calibration.temp;
  const margin = 0.5;
  if (prev === "Cool" && temp < coolMax + margin) return "Cool";
  if (prev === "Hot" && temp > hotMin - margin) return "Hot";
  if (temp < coolMax) return "Cool";
  if (temp > normalMax) return "Hot";
  return "Normal";
};

export default function useAgroSmartLiveData({ fastMode = false } = {}) {
  const [data, setData] = useState(DEFAULT_DATA); // smoothed
  const [raw, setRaw] = useState(DEFAULT_DATA);
  const [connected, setConnected] = useState(false);
  const [error, setError] = useState(null);
  const [tick, setTick] = useState(0);
  const [lastUpdated, setLastUpdated] = useState(null);
  const [states, setStates] = useState({
    soil: "Optimal",
    light: "Normal",
    temp: "Normal",
    irrigation: false,
  });
  const [normalized, setNormalized] = useState({
    soil: 0,
    light: 0,
    wetness: 0,
    brightness: 0,
  });

  const smoothRef = useRef({
    soilRaw: DEFAULT_DATA.soilMoisture,
    lightRaw: DEFAULT_DATA.lightLevel,
    temp: DEFAULT_DATA.temperature,
    wetness: clamp01(
      (calibration.soil.dry - DEFAULT_DATA.soilMoisture) /
        Math.max(calibration.soil.dry - calibration.soil.wet, 1),
    ),
    brightness: clamp01(
      (calibration.light.dark - DEFAULT_DATA.lightLevel) /
        Math.max(calibration.light.dark - calibration.light.bright, 1),
    ),
  });
  const prevStateRef = useRef({
    soil: "Optimal",
    light: "Normal",
    temp: "Normal",
  });

  useEffect(() => {
    let unsubscribe = null;
    let cancelled = false;
    const fallbackTimer = setTimeout(() => setConnected(false), 7000);

    (async () => {
      try {
        await authReady;
      } catch (e) {
        console.error("[SensorTwin] auth readiness failed", e);
      }
      if (cancelled) return;

      const dataRef = ref(database, "/AgroSmart/currentData");
      unsubscribe = onValue(
        dataRef,
        (snapshot) => {
          const val = snapshot.val() || {};
          const rawVal = {
            temperature: getFirstNumber(
              val,
              ["Temperature", "temperature", "temp"],
              DEFAULT_DATA.temperature,
            ),
            humidity: getFirstNumber(
              val,
              ["Humidity", "humidity"],
              DEFAULT_DATA.humidity,
            ),
            soilMoisture: getFirstNumber(
              val,
              [
                "SoilMoisture (in air)",
                "soilMoisture",
                "SoilMoisture",
                "soil",
                "soil_moisture",
                "soilMoistureInAir",
              ],
              DEFAULT_DATA.soilMoisture,
            ),
            lightLevel: getFirstNumber(
              val,
              ["LightLevel", "lightLevel", "light", "light_level"],
              DEFAULT_DATA.lightLevel,
            ),
            irrigationStatus: parseIrrigationStatus(val),
          };

          const parsed = { ...rawVal };

          const wetnessNorm = clamp01(
            (calibration.soil.dry - rawVal.soilMoisture) /
              Math.max(calibration.soil.dry - calibration.soil.wet, 1),
          );
          const brightnessNorm = clamp01(
            (calibration.light.dark - rawVal.lightLevel) /
              Math.max(calibration.light.dark - calibration.light.bright, 1),
          );

          const wetAlpha = fastMode ? 1 : calibration.smoothing.wetnessAlpha;
          const lightAlpha = fastMode ? 1 : calibration.smoothing.brightnessAlpha;
          const tempAlpha = fastMode ? 1 : calibration.smoothing.tempAlpha;

          smoothRef.current.soilRaw = smoothValue(
            smoothRef.current.soilRaw,
            rawVal.soilMoisture,
            wetAlpha,
          );
          smoothRef.current.lightRaw = smoothValue(
            smoothRef.current.lightRaw,
            rawVal.lightLevel,
            lightAlpha,
          );
          smoothRef.current.temp = smoothValue(
            smoothRef.current.temp,
            rawVal.temperature,
            tempAlpha,
          );
          smoothRef.current.wetness = smoothValue(
            smoothRef.current.wetness,
            wetnessNorm,
            wetAlpha,
          );
          smoothRef.current.brightness = smoothValue(
            smoothRef.current.brightness,
            brightnessNorm,
            lightAlpha,
          );

          const soilState = hysteresisSoil(
            smoothRef.current.wetness,
            prevStateRef.current.soil,
          );
          const lightState = hysteresisLight(
            smoothRef.current.brightness,
            prevStateRef.current.light,
          );
          const tempState = hysteresisTemp(
            rawVal.temperature,
            prevStateRef.current.temp,
          );
          const irrigationOn = !!rawVal.irrigationStatus;

          prevStateRef.current = {
            soil: soilState,
            light: lightState,
            temp: tempState,
          };

          const smoothed = {
            temperature: smoothRef.current.temp,
            humidity: rawVal.humidity,
            soilMoisture: smoothRef.current.soilRaw,
            lightLevel: smoothRef.current.lightRaw,
            irrigationStatus: irrigationOn,
          };

          const stamp = Date.now();

          setData({ ...smoothed, __ts: stamp });
          setRaw({ ...parsed, __ts: stamp });
          setStates({
            soil: soilState,
            light: lightState,
            temp: tempState,
            irrigation: irrigationOn,
          });
          setNormalized({
            soil: smoothRef.current.wetness,
            light: smoothRef.current.brightness,
            wetness: smoothRef.current.wetness,
            brightness: smoothRef.current.brightness,
            __ts: stamp,
          });
          setConnected(true);
          setError(null);
          setTick((t) => t + 1);
          setLastUpdated(new Date().toISOString());
          console.log("[SensorTwin] update", Date.now(), parsed);
          clearTimeout(fallbackTimer);
        },
        (listenerError) => {
          if (listenerError?.code === "PERMISSION_DENIED") {
            console.error("Digital Twin listener permission denied", listenerError);
          } else {
            console.error("Digital Twin listener error", listenerError);
          }
          setConnected(false);
          setError(listenerError);
        },
      );
    })();

    return () => {
      cancelled = true;
      clearTimeout(fallbackTimer);
      if (unsubscribe) unsubscribe();
    };
  }, []);

  return {
    data,
    raw,
    normalized,
    states,
    irrigationOn: Boolean(data.irrigationStatus),
    connected,
    error,
    tick,
    lastUpdated,
    calibration,
  };
}

function smoothValue(current, target, alpha) {
  if (current === undefined || current === null) return target;
  return current + alpha * (target - current);
}

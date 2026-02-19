import { useEffect, useRef, useState } from "react";
import { onValue, ref } from "firebase/database";
import { database } from "../firebase";
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

const parseIrrigationStatus = (payload = {}) => {
  const candidates = [
    payload.irrigationStatus,
    payload.irrigation,
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

const hysteresisSoil = (value, prev) => {
  const { dryMax, optimalMax, wetMin, min, max } = calibration.soil;
  const margin = (max - min) * 0.05;
  if (prev === "Dry" && value < dryMax + margin) return "Dry";
  if (prev === "Wet" && value > wetMin - margin) return "Wet";
  if (value < dryMax) return "Dry";
  if (value > wetMin) return "Wet";
  if (value >= dryMax - margin && value <= optimalMax + margin) return "Optimal";
  return prev || "Optimal";
};

const hysteresisLight = (norm, prev) => {
  const low = 0.3;
  const high = 0.75;
  const margin = 0.05;
  if (prev === "Low" && norm < low + margin) return "Low";
  if (prev === "High" && norm > high - margin) return "High";
  if (norm < low) return "Low";
  if (norm > high) return "High";
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

export default function useAgroSmartLiveData() {
  const [data, setData] = useState(DEFAULT_DATA); // smoothed
  const [raw, setRaw] = useState(DEFAULT_DATA);
  const [connected, setConnected] = useState(false);
  const [error, setError] = useState(null);
  const [tick, setTick] = useState(0);
  const [states, setStates] = useState({ soil: "Optimal", light: "Normal", temp: "Normal", irrigation: false });
  const [normalized, setNormalized] = useState({ soil: 0, light: 0 });

  const smoothRef = useRef({
    soil: DEFAULT_DATA.soilMoisture,
    light: DEFAULT_DATA.lightLevel,
    temp: DEFAULT_DATA.temperature,
  });
  const prevStateRef = useRef({ soil: "Optimal", light: "Normal", temp: "Normal" });

  useEffect(() => {
    const dataRef = ref(database, "/AgroSmart/currentData");
    const fallbackTimer = setTimeout(() => setConnected(false), 7000);

    const unsubscribe = onValue(
      dataRef,
      (snapshot) => {
        const val = snapshot.val() || {};
        const rawVal = {
          temperature: toNumber(val.temperature, DEFAULT_DATA.temperature),
          humidity: toNumber(val.humidity, DEFAULT_DATA.humidity),
          soilMoisture: toNumber(val.soilMoisture, DEFAULT_DATA.soilMoisture),
          lightLevel: toNumber(val.lightLevel, DEFAULT_DATA.lightLevel),
          irrigationStatus: parseIrrigationStatus(val),
        };

        const soilNorm = clamp01((rawVal.soilMoisture - calibration.soil.min) / (calibration.soil.max - calibration.soil.min));
        let lightNorm = clamp01((rawVal.lightLevel - calibration.light.min) / (calibration.light.max - calibration.light.min));
        if (calibration.light.invert) lightNorm = 1 - lightNorm;

        smoothRef.current.soil = smoothValue(smoothRef.current.soil, rawVal.soilMoisture, calibration.smoothing.soilAlpha);
        smoothRef.current.light = smoothValue(smoothRef.current.light, rawVal.lightLevel, calibration.smoothing.lightAlpha);
        smoothRef.current.temp = smoothValue(smoothRef.current.temp, rawVal.temperature, calibration.smoothing.tempAlpha);

        const soilState = hysteresisSoil(rawVal.soilMoisture, prevStateRef.current.soil);
        const lightState = hysteresisLight(lightNorm, prevStateRef.current.light);
        const tempState = hysteresisTemp(rawVal.temperature, prevStateRef.current.temp);
        const irrigationOn = !!rawVal.irrigationStatus;

        prevStateRef.current = { soil: soilState, light: lightState, temp: tempState };

        const smoothed = {
          temperature: smoothRef.current.temp,
          humidity: rawVal.humidity,
          soilMoisture: smoothRef.current.soil,
          lightLevel: smoothRef.current.light,
          irrigationStatus: irrigationOn,
        };

        setData(smoothed);
        setRaw(rawVal);
        setStates({ soil: soilState, light: lightState, temp: tempState, irrigation: irrigationOn });
        setNormalized({ soil: soilNorm, light: lightNorm });
        setConnected(true);
        setError(null);
        setTick((t) => t + 1);
        clearTimeout(fallbackTimer);
      },
      (error) => {
        console.error("Digital Twin listener error", error);
        setConnected(false);
        setError(error);
      },
    );

    return () => {
      clearTimeout(fallbackTimer);
      unsubscribe();
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
    calibration,
  };
}

function smoothValue(current, target, alpha){
  if(current === undefined || current === null) return target
  return current + alpha * (target - current)
}

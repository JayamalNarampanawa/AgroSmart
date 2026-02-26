// Environment State Engine for AR overlays and monitoring

const SEVERITY_ORDER = { info: 0, warn: 1, critical: 2 };

const FEATURE_LABELS = {
  temperature: "Temperature",
  humidity: "Humidity",
  rainfall: "Rainfall",
  ph: "pH",
  soilMoisture: "Soil moisture",
  lightLevel: "Light level",
};

const toNumberOrNull = (v) => {
  if (v === null || v === undefined) return null;
  const n = typeof v === "number" ? v : Number(v);
  return Number.isFinite(n) ? n : null;
};

export function clamp(n, min, max) {
  return Math.max(min, Math.min(max, n));
}

export function normalizeCropKey(cropName) {
  if (!cropName) return null;
  return String(cropName).trim().toLowerCase().replace(/\s+/g, "");
}

export function evaluateFeature(current, ideal, tolerancePct, minAbsTol) {
  const currentVal = toNumberOrNull(current);
  const idealVal = toNumberOrNull(ideal);

  if (currentVal === null || idealVal === null) {
    return {
      status: "UNKNOWN",
      severity: "info",
      diff: 0,
      pctDiff: 0,
      message: "No data",
      band: null,
      current: currentVal,
      ideal: idealVal,
    };
  }

  const band = Math.max(Math.abs(idealVal) * tolerancePct, minAbsTol);
  const lower = idealVal - band;
  const upper = idealVal + band;
  const diff = currentVal - idealVal;
  const pctDiff = idealVal !== 0 ? diff / idealVal : 0;

  let status = "OK";
  let severity = "info";
  let message = "Within ideal band";

  if (currentVal < lower) {
    status = "LOW";
    const over = lower - currentVal;
    severity = over > band ? "critical" : "warn";
    message =
      severity === "critical"
        ? "Significantly below ideal"
        : "Below ideal range";
  } else if (currentVal > upper) {
    status = "HIGH";
    const over = currentVal - upper;
    severity = over > band ? "critical" : "warn";
    message =
      severity === "critical"
        ? "Significantly above ideal"
        : "Above ideal range";
  }

  return {
    status,
    severity,
    diff,
    pctDiff,
    message,
    band,
    current: currentVal,
    ideal: idealVal,
  };
}

function evaluateSoilMoisture(value) {
  const current = toNumberOrNull(value);
  if (current === null) {
    return {
      status: "UNKNOWN",
      severity: "info",
      diff: 0,
      pctDiff: 0,
      message: "No soil data",
      band: null,
      current,
    };
  }

  const dryThreshold = 3200;
  const wetThreshold = 2000;
  const veryDry = 3600;
  const veryWet = 1600;

  let status = "OK";
  let severity = "info";
  let message = "Within expected band";

  if (current > dryThreshold) {
    status = "LOW";
    severity = current > veryDry ? "critical" : "warn";
    message =
      severity === "critical" ? "Soil is very dry" : "Soil moisture low";
  } else if (current < wetThreshold) {
    status = "HIGH";
    severity = current < veryWet ? "critical" : "warn";
    message =
      severity === "critical" ? "Soil is waterlogged" : "Soil moisture high";
  }

  return {
    status,
    severity,
    diff: 0,
    pctDiff: 0,
    message,
    band: null,
    current,
  };
}

function evaluateLight(value) {
  const current = toNumberOrNull(value);
  if (current === null) {
    return {
      status: "UNKNOWN",
      severity: "info",
      diff: 0,
      pctDiff: 0,
      message: "No light data",
      band: null,
      current,
    };
  }

  const low = 1200;
  const high = 3500;
  const veryLow = 900;
  const veryHigh = 3800;

  let status = "OK";
  let severity = "info";
  let message = "Within expected band";

  if (current < low) {
    status = "LOW";
    severity = current < veryLow ? "critical" : "warn";
    message =
      severity === "critical" ? "Light critically low" : "Light below ideal";
  } else if (current > high) {
    status = "HIGH";
    severity = current > veryHigh ? "critical" : "warn";
    message =
      severity === "critical" ? "Light critically high" : "Light above ideal";
  }

  return {
    status,
    severity,
    diff: 0,
    pctDiff: 0,
    message,
    band: null,
    current,
  };
}

export function evaluateEnvironment({ live = {}, cropKey, ideals } = {}) {
  const normalizedKey = normalizeCropKey(cropKey);
  const idealSet = (ideals && normalizedKey && ideals[normalizedKey]) || null;

  const phFeature = evaluateFeature(
    live.ph ?? live.pH,
    idealSet?.ph,
    0.08,
    0.4,
  );

  const features = {
    temperature: evaluateFeature(
      live.temperature,
      idealSet?.temperature,
      0.1,
      1.5,
    ),
    humidity: evaluateFeature(live.humidity, idealSet?.humidity, 0.12, 6),
    rainfall:
      idealSet?.rainfall !== undefined
        ? evaluateFeature(live.rainfall, idealSet?.rainfall, 0.15, 8)
        : null,
    ph: phFeature,
    pH: phFeature,
  };

  const extraFeatures = {
    soilMoisture: evaluateSoilMoisture(live.soilMoisture),
    lightLevel: evaluateLight(live.lightLevel),
  };

  const candidates = [
    { name: "temperature", data: features.temperature },
    { name: "humidity", data: features.humidity },
    { name: "rainfall", data: features.rainfall },
    { name: "ph", data: features.ph },
    { name: "soilMoisture", data: extraFeatures.soilMoisture },
    { name: "lightLevel", data: extraFeatures.lightLevel },
  ].filter((c) => c.data && c.data.status && c.data.status !== "UNKNOWN");

  let overall = { level: "Stable", message: "Within acceptable bands." };

  if (candidates.length === 0) {
    overall = { level: "Stable", message: "Insufficient data to evaluate." };
  } else {
    const worst = candidates.reduce((acc, cur) => {
      const currSeverity = SEVERITY_ORDER[cur.data.severity] ?? 0;
      const accSeverity = acc ? (SEVERITY_ORDER[acc.data.severity] ?? 0) : -1;
      return currSeverity > accSeverity ? cur : acc;
    }, null);

    const worstSeverity = worst ? worst.data.severity : "info";
    if (worstSeverity === "critical") {
      overall = {
        level: "Critical",
        message: `${FEATURE_LABELS[worst.name] || worst.name} is ${worst.data.status}.`,
      };
    } else if (worstSeverity === "warn") {
      overall = {
        level: "Warning",
        message: `${FEATURE_LABELS[worst.name] || worst.name} is drifting ${worst.data.status === "LOW" ? "low" : "high"}.`,
      };
    }
  }

  return {
    cropKey: normalizedKey,
    features,
    extraFeatures,
    overall,
  };
}

export default evaluateEnvironment;

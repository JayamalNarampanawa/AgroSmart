// src/services/mlService.js
import { envConfig } from "../config/env";

// Hard-pin to hosted Render API to avoid accidental localhost calls
const BASE_URL = "https://agrosmart-ml-api.onrender.com";

console.log("[AgroSmart] ML BASE (envConfig):", BASE_URL);
console.log(
  "[AgroSmart] ML BASE (vite):",
  import.meta.env.VITE_ML_API_BASE_URL,
);

export async function getMlPrediction(payload) {
  const url = `${BASE_URL.replace(/\/$/, "")}/predict`;

  const res = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });

  if (!res.ok) {
    let details = "";
    try {
      const err = await res.json();
      if (err?.detail)
        details = `: ${typeof err.detail === "string" ? err.detail : JSON.stringify(err.detail)}`;
    } catch (e) {}
    throw new Error(
      `ML API request failed with status ${res.status}${details}`,
    );
  }

  const data = await res.json();

  // Normalize response keys (Render API commonly returns predicted_crop)
  const predictedCrop =
    data.predicted_crop ??
    data.predictedCrop ??
    data.crop ??
    data.prediction ??
    null;

  return {
    predictedCrop,
    confidence: data.confidence ?? null,
    probabilities: data.probabilities ?? null,
  };
}

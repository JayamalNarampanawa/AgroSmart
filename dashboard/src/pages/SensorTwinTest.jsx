import React, { Suspense, useMemo } from "react";
import { motion } from "framer-motion";
import { useSearchParams } from "react-router-dom";

import SensorBarsScene, { SensorDebugOverlay } from "../three/SensorBarsScene";
import useAgroSmartLiveData from "../three/useAgroSmartLiveData";
import useRecommendationData from "../hooks/useRecommendationData";
import useMlValidation from "../hooks/useMlValidation";
import HologramCard from "../components/ui/HologramCard";
import { cropIdeals } from "../data/cropIdeals";
import { extractKeyFeatures } from "../utils/reasonToFeature";
import { generateSuggestions } from "../utils/generateSuggestions";

const clamp01 = (v) => Math.max(0, Math.min(1, v));

function computeWetness(raw) {
    // Soil: WET=1369, DRY=2606 (higher=drier) => wetness 1..0
    return 1 - clamp01((raw - 1369) / (2606 - 1369));
}

function computeBrightness(raw) {
    // Light: BRIGHT~10, DARK~4095 (lower=brighter) => brightness 1..0
    return 1 - clamp01((raw - 10) / (4095 - 10));
}

export default function SensorTwinTest() {
    const [params] = useSearchParams();
    const debug = params.get("debug") === "1";

    const { data, raw, connected, tick, lastUpdated, normalized, error } =
        useAgroSmartLiveData({ fastMode: true });

    const recommendation = useRecommendationData();
    const { mlResult } = useMlValidation(recommendation);
    const keyFeatures = useMemo(() => extractKeyFeatures(recommendation?.reasons || []), [recommendation?.reasons]);

    const wetness = useMemo(() => computeWetness(raw.soilMoisture), [raw.soilMoisture]);
    const brightness = useMemo(() => computeBrightness(raw.lightLevel), [raw.lightLevel]);

    return (
        <div className="fixed inset-0 bg-[#05070a] text-slate-100">
            <LiveBadge connected={connected} tick={tick} lastUpdated={lastUpdated} />
            <IntelligenceOverlay recommendation={recommendation} mlResult={mlResult} current={raw} keyFeatures={keyFeatures} />
            <HookProbe raw={raw} tick={tick} lastUpdated={lastUpdated} error={error} />

            {debug && (
                <SensorDebugOverlay
                    connected={connected}
                    raw={raw}
                    wetness={wetness}
                    brightness={brightness}
                    tick={tick}
                    lastUpdated={lastUpdated}
                    normalized={normalized}
                />
            )}

            <motion.div
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ duration: 0.6, ease: "easeOut" }}
                className="absolute inset-0"
            >
                <Suspense fallback={null}>
                    <SensorBarsScene
                        data={data}
                        raw={raw}
                        connected={connected}
                        tick={tick}
                        recommendation={recommendation}
                    />
                </Suspense>
            </motion.div>
        </div>
    );
}

function IntelligenceOverlay({ recommendation, mlResult, current, keyFeatures }) {
    const primaryCrop = recommendation?.recommendedCrop || recommendation?.bestCrop || "—";
    const matchLevel = recommendation?.matchLevel || "Unknown";
    const bestScore = typeof recommendation?.bestScore === "number" && !Number.isNaN(recommendation.bestScore)
        ? recommendation.bestScore.toFixed(2)
        : "--";
    const reasons = Array.isArray(recommendation?.reasons) ? recommendation.reasons.filter(Boolean) : [];
    const reason1 = reasons[0] || "No explanation yet";
    const reason2 = reasons[1] || (reasons[0] ? "Collecting more data..." : "Waiting for AI input...");

    const mlCrop = mlResult?.predictedCrop || mlResult?.crop || null;
    const mlConfRaw = typeof mlResult?.confidence === "number" && !Number.isNaN(mlResult.confidence) ? mlResult.confidence : null;
    const mlConf = mlConfRaw == null ? null : (mlConfRaw > 1 ? Math.min(mlConfRaw, 100) : Math.min(mlConfRaw * 100, 100));
    const mlAvailable = !!(mlCrop && mlConf !== null);
    const agrees = mlAvailable && primaryCrop !== "—" ? mlCrop?.toLowerCase?.() === primaryCrop.toLowerCase() : null;
    const agreementLabel = !mlAvailable ? "ML: offline / not available" : agrees ? "agrees ✅" : "differs ⚠️";

    const cropKey = primaryCrop?.toLowerCase?.() || '';
    const ideal = cropIdeals[cropKey] || null;
    const currentForSuggestions = {
        temperature: current?.temperature,
        humidity: current?.humidity,
        rainfall: recommendation?.inputUsed?.rainfall ?? null,
        ph: recommendation?.inputUsed?.ph ?? null,
    };
    const suggestions = useMemo(
        () => generateSuggestions({ current: currentForSuggestions, ideal: ideal || {}, keyFeatures }),
        [currentForSuggestions.temperature, currentForSuggestions.humidity, currentForSuggestions.rainfall, currentForSuggestions.ph, ideal, keyFeatures]
    );

    return (
        <div className="absolute left-4 top-16 z-30 w-[360px] max-w-[92vw]">
            <HologramCard title="Intelligence" className="p-4">
                <div className="space-y-1 text-sm text-slate-100">
                    <div className="text-xs uppercase tracking-[0.18em] text-cyan-200">Primary Recommendation</div>
                    <div className="text-lg font-semibold capitalize">{primaryCrop}</div>
                    <div className="text-xs text-slate-300">Match: {matchLevel} · Score {bestScore}</div>
                </div>
                <div className="mt-3 space-y-1 text-sm text-slate-200">
                    <div>1) {reason1}</div>
                    <div>2) {reason2}</div>
                </div>
                <div className="mt-4 rounded-xl border border-cyan-400/20 bg-cyan-400/5 p-3 text-sm text-slate-100">
                    <div className="flex items-center justify-between">
                        <span className="font-semibold">ML validation</span>
                        <span className="text-xs uppercase tracking-wide">{agreementLabel}</span>
                    </div>
                    {mlAvailable && (
                        <div className="mt-1 text-xs text-slate-200">
                            <div>Predicted: <span className="font-semibold capitalize">{mlCrop}</span></div>
                            <div>Confidence: <span className="font-semibold">{Math.round(mlConf)}%</span></div>
                        </div>
                    )}
                    {!mlAvailable && (
                        <div className="mt-1 text-xs text-slate-300">ML: offline / not available</div>
                    )}
                </div>

                <div className="mt-3">
                    <div className="text-xs uppercase tracking-[0.18em] text-cyan-200">Recommended Actions</div>
                    <ul className="mt-2 space-y-1 text-sm text-slate-100">
                        {Array.isArray(suggestions) && suggestions.length > 0 ? suggestions.map((s, idx) => (
                            <li key={idx} className="rounded-lg border border-cyan-400/20 bg-cyan-400/5 px-3 py-2">{s}</li>
                        )) : <li className="text-xs text-slate-400">No actions available yet.</li>}
                    </ul>
                </div>
            </HologramCard>
        </div>
    );
}

function HookProbe({ raw, tick, lastUpdated, error }) {
    return (
        <div className="fixed top-3 right-3 z-50 w-[420px] max-h-[70vh] overflow-auto rounded-xl border border-cyan-400/30 bg-black/70 p-3 text-xs text-cyan-200">
            <div className="flex items-center justify-between">
                <div className="font-semibold">HOOK tick: {tick}</div>
                <div className="opacity-70">{lastUpdated || "—"}</div>
            </div>
            {error && (
                <div className="mt-2 rounded-md border border-rose-400/50 bg-rose-900/60 px-2 py-1 text-[11px] text-rose-100">
                    Error: {error.message || error.code || "Unknown error"}
                </div>
            )}
            <pre className="mt-2 whitespace-pre-wrap">{JSON.stringify(raw, null, 2)}</pre>
        </div>
    );
}

function LiveBadge({ connected, tick, lastUpdated }) {
    return (
        <div className="absolute left-4 top-4 z-20 rounded-full border border-white/10 bg-black/70 px-3 py-1.5 text-[11px] text-slate-100 shadow-md backdrop-blur">
            <span className={connected ? "text-emerald-300" : "text-amber-300"}>
                {connected ? "Connected" : "Disconnected"}
            </span>
            <span className="mx-2 text-slate-500">•</span>
            <span className="text-slate-200">tick {tick}</span>
            <span className="mx-2 text-slate-500">•</span>
            <span className="text-slate-400">{lastUpdated || "—"}</span>
        </div>
    );
}

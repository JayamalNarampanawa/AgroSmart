import React, { Suspense, useMemo } from "react";
import { motion } from "framer-motion";
import { useSearchParams, Link } from "react-router-dom";
import { Canvas } from "@react-three/fiber";
import { OrbitControls } from "@react-three/drei";

import SensorBarsScene, { SensorDebugOverlay } from "../three/SensorBarsScene";
import useAgroSmartLiveData from "../three/useAgroSmartLiveData";
import useRecommendationData from "../hooks/useRecommendationData";
import useMlValidation from "../hooks/useMlValidation";
import HologramCard from "../components/ui/HologramCard";
import WarehouseScene from "../components/warehouse/WarehouseScene";
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

            {/* Embedded AR prototype preview */}
            <div className="absolute right-4 top-16 z-30 w-[420px] max-w-[40vw] rounded-2xl border border-cyan-400/30 bg-slate-900/70 p-3 shadow-[0_0_24px_rgba(34,211,238,0.18)] backdrop-blur">
                <div className="flex items-center justify-between text-xs uppercase tracking-[0.18em] text-cyan-200/80 px-1 pb-2">
                    <span>AR Preview</span>
                    <span className="text-[10px] text-slate-300">live</span>
                </div>
                <div className="h-[280px] w-full overflow-hidden rounded-xl border border-cyan-400/20 bg-slate-900/80">
                    <Canvas shadows camera={{ position: [0.8, 0.55, 1.2], fov: 55 }} gl={{ antialias: true }}>
                        <Suspense fallback={null}>
                            <OrbitControls
                                enableDamping
                                dampingFactor={0.08}
                                maxDistance={2.5}
                                minDistance={0.6}
                                autoRotate
                                autoRotateSpeed={0.4}
                            />
                            <WarehouseScene live={data} />
                        </Suspense>
                    </Canvas>
                </div>
            </div>

            <div className="absolute bottom-5 left-1/2 z-30 -translate-x-1/2">
                <div className="flex items-center gap-3">
                    <Link
                        to="/dashboard"
                        className="inline-flex items-center gap-2 rounded-xl border border-slate-400/40 bg-slate-700/40 px-4 py-3 text-sm font-semibold text-slate-100 shadow-[0_0_14px_rgba(148,163,184,0.25)] transition-all duration-300 hover:scale-[1.02] hover:border-slate-300/70 hover:bg-slate-600/50 focus:outline-none focus:ring-2 focus:ring-slate-300/60"
                    >
                        Back to Dashboard
                    </Link>
                    <Link
                        to="/ar"
                        className="inline-flex items-center gap-2 rounded-xl border border-cyan-400/40 bg-cyan-500/10 px-5 py-3 text-sm font-semibold text-cyan-100 shadow-[0_0_18px_rgba(34,211,238,0.25)] transition-all duration-300 hover:scale-[1.02] hover:border-cyan-400/70 hover:bg-cyan-500/20 focus:outline-none focus:ring-2 focus:ring-cyan-400/60"
                    >
                        Enter AR Mode
                    </Link>
                </div>
            </div>
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

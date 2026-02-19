import React, { Suspense, useMemo } from "react";
import { motion } from "framer-motion";
import { useSearchParams } from "react-router-dom";

import SensorBarsScene, { SensorDebugOverlay } from "../three/SensorBarsScene";
import useAgroSmartLiveData from "../three/useAgroSmartLiveData";

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

    const wetness = useMemo(() => computeWetness(raw.soilMoisture), [raw.soilMoisture]);
    const brightness = useMemo(() => computeBrightness(raw.lightLevel), [raw.lightLevel]);

    return (
        <div className="fixed inset-0 bg-[#05070a] text-slate-100">
            <LiveBadge connected={connected} tick={tick} lastUpdated={lastUpdated} />
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
                    />
                </Suspense>
            </motion.div>
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

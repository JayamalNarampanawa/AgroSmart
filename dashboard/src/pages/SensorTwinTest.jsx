import React, { Suspense, useMemo } from 'react'
import { motion } from 'framer-motion'
import { useSearchParams } from 'react-router-dom'
import SensorBarsScene, { SensorDebugOverlay } from '../three/SensorBarsScene'
import useAgroSmartLiveData from '../three/useAgroSmartLiveData'

const clamp01 = (v) => Math.max(0, Math.min(1, v))

function computeWetness(raw) {
    return 1 - clamp01((raw - 1369) / (2606 - 1369))
}

function computeBrightness(raw) {
    return 1 - clamp01((raw - 10) / (4095 - 10))
}

export default function SensorTwinTest() {
    const [params] = useSearchParams()
    const debug = params.get('debug') === '1'
    const { data, raw, connected, tick, lastUpdated, normalized } = useAgroSmartLiveData({ fastMode: true })
    const wetness = useMemo(() => computeWetness(raw.soilMoisture), [raw.soilMoisture])
    const brightness = useMemo(() => computeBrightness(raw.lightLevel), [raw.lightLevel])

    return (
        <div className="fixed inset-0 bg-[#05070a] text-slate-100">
            <LiveBadge connected={connected} tick={tick} lastUpdated={lastUpdated} />

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
                transition={{ duration: 0.6, ease: 'easeOut' }}
                className="absolute inset-0"
            >
                <Suspense fallback={null}>
                    <SensorBarsScene
                        key={tick}
                        data={data}
                        raw={raw}
                        connected={connected}
                        tick={tick}
                    />
                </Suspense>
            </motion.div>
        </div>
    )
}

function LiveBadge({ connected, tick, lastUpdated }) {
    return (
        <div className="absolute left-4 top-4 z-20 rounded-full border border-white/10 bg-black/70 px-3 py-1.5 text-[11px] text-slate-100 shadow-md backdrop-blur">
            <span className={connected ? 'text-emerald-300' : 'text-amber-300'}>{connected ? 'Connected' : 'Disconnected'}</span>
            <span className="mx-2 text-slate-500">•</span>
            <span className="text-slate-200">tick {tick}</span>
            <span className="mx-2 text-slate-500">•</span>
            <span className="text-slate-400">{lastUpdated || '—'}</span>
        </div>
    )
}

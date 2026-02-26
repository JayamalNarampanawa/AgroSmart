import React, { Suspense, useEffect, useMemo } from 'react'
import { Canvas } from '@react-three/fiber'
import { OrbitControls } from '@react-three/drei'
import { Link } from 'react-router-dom'
import WarehouseScene from '../components/warehouse/WarehouseScene'
import useAgroSmartLiveData from '../three/useAgroSmartLiveData'
import useRecommendationData from '../hooks/useRecommendationData'
import { cropIdeals } from '../data/cropIdeals'
import { evaluateEnvironment, normalizeCropKey } from '../utils/environmentStateEngine'
import { evaluateAlerts } from '../utils/environmentAlertEngine'
import useReplayBuffer from '../hooks/useReplayBuffer'
import useReplayController from '../hooks/useReplayController'
import ReplayControls from '../components/ReplayControls'
import useReplayHistoryLoader from '../hooks/useReplayHistoryLoader'

export default function ArView() {
    const { data: liveData = {} } = useAgroSmartLiveData({ fastMode: true })
    const { buffer, isRecording, clear, pause: pauseRecording, resume: resumeRecording, setBufferExternal } = useReplayBuffer({
        source: { ...liveData },
        throttleMs: 1000,
        maxPoints: 900,
        enabled: true,
    })
    const { loadHistory, loading: loadingHistory, error: historyError } = useReplayHistoryLoader({ limit: 900 })
    const {
        mode,
        replayIndex,
        isPlaying,
        speed,
        setSpeed,
        togglePlay,
        seek,
        step,
        goLive,
        enterReplayAtEnd,
        effectiveData,
        currentSnapshot,
    } = useReplayController({
        buffer,
        liveData,
        initialMode: 'LIVE',
        initialSpeed: 1,
        persistKey: 'agrosmart-replay-ar',
    })

    useEffect(() => {
        if (mode === 'REPLAY') pauseRecording()
        else resumeRecording()
    }, [mode, pauseRecording, resumeRecording])

    const handleLoadHistory = async () => {
        const snapshots = await loadHistory()
        setBufferExternal(snapshots)
        if (snapshots.length) enterReplayAtEnd()
    }

    const sensorData = effectiveData || liveData || {}
    const timelineTs = mode === 'REPLAY' ? currentSnapshot?.ts ?? currentSnapshot?.__ts : liveData?.__ts
    const liveLabel = liveData?.__ts ? new Date(liveData.__ts).toLocaleTimeString([], { hour12: false }) : null
    const recommendation = useRecommendationData()

    const cropKey = useMemo(
        () => normalizeCropKey(recommendation?.recommendedCrop || recommendation?.bestCrop || recommendation?.crop),
        [recommendation?.recommendedCrop, recommendation?.bestCrop, recommendation?.crop]
    )

    const envState = useMemo(
        () => evaluateEnvironment({ live: sensorData, cropKey, ideals: cropIdeals }),
        [sensorData, cropKey]
    )

    const alerts = useMemo(
        () =>
            evaluateAlerts({
                live: sensorData,
                cropIdeals,
                recommendedCrop: recommendation?.crop,
            }),
        [sensorData, recommendation]
    )

    return (
        <div className="min-h-screen bg-slate-950 text-slate-100">
            <header className="flex items-center justify-between border-b border-white/10 bg-slate-900/70 px-6 py-4 backdrop-blur">
                <div>
                    <div className="text-[11px] uppercase tracking-[0.28em] text-cyan-200">AgroSmart 2.0</div>
                    <div className="text-lg font-semibold text-white">AR Mode (3D)</div>
                </div>
                <div className="flex items-center gap-3">
                    <Link
                        to="/dashboard"
                        className="inline-flex items-center gap-2 rounded-lg border border-slate-300/40 bg-slate-700/30 px-3 py-2 text-sm font-semibold text-slate-100 transition-all duration-200 hover:border-slate-200/70 hover:bg-slate-600/40"
                    >
                        Dashboard
                    </Link>
                    <Link
                        to="/twin"
                        className="inline-flex items-center gap-2 rounded-lg border border-cyan-400/40 bg-cyan-500/10 px-3 py-2 text-sm font-semibold text-cyan-100 transition-all duration-200 hover:border-cyan-400/70 hover:bg-cyan-500/20"
                    >
                        Back to Twin
                    </Link>
                </div>
            </header>

            <div className="border-b border-white/10 bg-slate-950 px-6 py-4">
                <ReplayControls
                    mode={mode}
                    isPlaying={isPlaying}
                    speed={speed}
                    replayIndex={replayIndex}
                    buffer={buffer}
                    onPlayPause={togglePlay}
                    onSeek={seek}
                    onStep={step}
                    onSpeedChange={setSpeed}
                    onClear={clear}
                    onGoLive={goLive}
                    onLoadHistory={handleLoadHistory}
                    loadingHistory={loadingHistory}
                    historyError={historyError?.message || historyError}
                    isRecording={isRecording}
                    liveLabel={liveLabel}
                    timestamp={timelineTs}
                />
            </div>

            <div className="relative w-full h-[calc(100vh-72px)]">
                <Canvas shadows camera={{ position: [0.6, 0.4, 0.8], fov: 50 }} gl={{ antialias: true, powerPreference: 'high-performance' }}>
                    <Suspense fallback={null}>
                        <OrbitControls enableDamping dampingFactor={0.08} maxDistance={2} minDistance={0.4} />
                        <WarehouseScene live={sensorData} envState={envState} alerts={alerts} />
                    </Suspense>
                </Canvas>

                <div className="absolute top-6 left-6 w-80 rounded-2xl border border-white/10 bg-slate-900/80 px-4 py-3 text-sm text-slate-100 backdrop-blur">
                    <div className="text-[11px] uppercase tracking-[0.18em] text-cyan-200/80">Intelligence Summary</div>
                    <div className="mt-2 flex items-center justify-between">
                        <span className="text-slate-300">Crop</span>
                        <span className="font-semibold text-white">{cropKey || '—'}</span>
                    </div>
                    <div className="mt-1 flex items-center justify-between">
                        <span className="text-slate-300">Overall</span>
                        <span className="font-semibold text-white">{envState?.overall?.level || '—'}</span>
                    </div>
                    {envState?.overall?.message && <div className="mt-1 text-xs text-slate-300">{envState.overall.message}</div>}
                    {recommendation?.matchLevel && (
                        <div className="mt-2 flex items-center justify-between">
                            <span className="text-slate-300">Match</span>
                            <span className="font-semibold text-white">{recommendation.matchLevel}</span>
                        </div>
                    )}
                    {recommendation?.bestScore !== undefined && (
                        <div className="mt-1 flex items-center justify-between text-xs text-slate-300">
                            <span>Score</span>
                            <span className="text-white font-semibold">{Math.round(recommendation.bestScore)}</span>
                        </div>
                    )}

                    {alerts.length > 0 && (
                        <div className="mt-3 border-t border-white/10 pt-3">
                            <div className="mb-2 text-sm font-semibold">Active Alerts</div>
                            {alerts.map((a, i) => (
                                <div
                                    key={i}
                                    className={a.severity === 'critical' ? 'text-red-400 text-xs' : 'text-yellow-400 text-xs'}
                                >
                                    • {a.message}
                                </div>
                            ))}
                        </div>
                    )}
                </div>
            </div>
        </div>
    )
}

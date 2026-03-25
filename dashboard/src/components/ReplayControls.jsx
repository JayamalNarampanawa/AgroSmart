import React, { useEffect, useMemo, useRef } from 'react'

const speedOptions = [0.5, 1, 2, 4]
const historyModes = ['replace', 'append']

const formatTime = (ts) => {
    if (!ts) return '—'
    const d = new Date(ts)
    const ms = String(d.getMilliseconds()).padStart(3, '0')
    return `${d.toLocaleTimeString([], { hour12: false })}.${ms}`
}

const handleImportFile = (event, onImport) => {
    const file = event.target.files?.[0]
    if (!file) return
    const reader = new FileReader()
    reader.onload = async (e) => {
        try {
            const text = e.target?.result
            const parsed = JSON.parse(text)
            await onImport?.(parsed)
        } catch (err) {
            console.error('Import failed', err)
        } finally {
            event.target.value = ''
        }
    }
    reader.readAsText(file)
}

export default function ReplayControls({
    mode = 'LIVE',
    isPlaying = false,
    speed = 1,
    replayIndex = 0,
    buffer = [],
    onPlayPause,
    onSeek,
    onStep,
    onSpeedChange,
    onClear,
    onGoLive,
    onLoadHistory,
    loadingHistory = false,
    historyError,
    historyMode = 'replace',
    onHistoryModeChange,
    onExport,
    onImport,
    importError,
    isRecording = true,
    liveLabel,
    timestamp,
    replaySource = 'rolling',
    onJumpPumpOn,
    onJumpPumpOff,
    eventMessage,
    markers = [],
}) {
    const fileInputRef = useRef(null)
    const currentTs = useMemo(() => timestamp || buffer[replayIndex]?.ts || buffer[replayIndex]?.__ts, [timestamp, buffer, replayIndex])
    const bufferSize = buffer.length
    const sliderMax = Math.max(bufferSize - 1, 0)

    const markerMap = useMemo(() => {
        const last = Math.max(bufferSize - 1, 1)
        return markers.map((m) => ({
            ...m,
            left: `${Math.max(0, Math.min(100, (m.index / last) * 100))}%`,
        }))
    }, [markers, bufferSize])

    useEffect(() => {
        const handler = (e) => {
            const tag = e.target?.tagName
            if (tag === 'INPUT' || tag === 'TEXTAREA' || e.metaKey || e.ctrlKey || e.altKey) return
            if (e.code === 'Space') {
                e.preventDefault()
                onPlayPause?.()
            } else if (e.key === 'l' || e.key === 'L') {
                onGoLive?.()
            } else if (e.key === 'ArrowLeft') {
                onStep?.(-1)
            } else if (e.key === 'ArrowRight') {
                onStep?.(1)
            } else if (e.key === 'n' || e.key === 'N') {
                onJumpPumpOn?.()
            } else if (e.key === 'm' || e.key === 'M') {
                onJumpPumpOff?.()
            }
        }
        window.addEventListener('keydown', handler)
        return () => window.removeEventListener('keydown', handler)
    }, [onPlayPause, onGoLive, onStep, onJumpPumpOn, onJumpPumpOff])

    const sourceLabel = replaySource === 'firebase' ? 'Firebase' : replaySource === 'import' ? 'Import' : 'Rolling'
    const sourceTone = replaySource === 'firebase'
        ? 'border-blue-400/60 bg-blue-500/10 text-blue-100'
        : replaySource === 'import'
            ? 'border-amber-400/60 bg-amber-500/10 text-amber-100'
            : 'border-slate-600 bg-slate-800/60 text-slate-200'

    return (
        <div className="w-full rounded-2xl border border-cyan-400/30 bg-slate-900/70 p-4 shadow-[0_0_28px_rgba(34,211,238,0.18)] backdrop-blur">
            <div className="flex flex-wrap items-center gap-3 justify-between">
                <div className="flex items-center gap-2 text-xs font-semibold uppercase tracking-[0.25em]">
                    <span className={`inline-flex items-center gap-2 rounded-full px-3 py-1 border ${mode === 'LIVE' ? 'border-emerald-400/60 bg-emerald-500/10 text-emerald-100' : 'border-cyan-400/60 bg-cyan-500/10 text-cyan-100'}`}>
                        <span className={`h-2 w-2 rounded-full ${mode === 'LIVE' ? 'bg-emerald-300 animate-pulse' : 'bg-cyan-300'}`}></span>
                        {mode === 'LIVE' ? 'Live' : 'Replay'}
                    </span>
                    <span className="text-slate-400">|</span>
                    <span className="text-slate-300">{isRecording ? 'Recording' : 'Paused'}</span>
                    <span className={`ml-2 inline-flex items-center gap-2 rounded-full px-3 py-1 border ${sourceTone}`}>
                        <span className="h-1.5 w-1.5 rounded-full bg-slate-300" />
                        Source: {sourceLabel}
                    </span>
                </div>
                <div className="flex items-center gap-2 text-[11px] text-slate-300">
                    <span>Buffer</span>
                    <span className="rounded-full bg-slate-800/80 px-2 py-0.5 text-cyan-100 border border-cyan-400/40">{bufferSize}</span>
                    {liveLabel && (
                        <span className="ml-2 inline-flex items-center gap-1 rounded-full border border-emerald-400/40 bg-emerald-500/10 px-2 py-0.5 text-emerald-100">
                            <span className="h-1.5 w-1.5 rounded-full bg-emerald-300 animate-pulse" />
                            {liveLabel}
                        </span>
                    )}
                </div>
            </div>

            <div className="mt-4 flex flex-col gap-3">
                <div className="flex items-center gap-2">
                    <button
                        type="button"
                        onClick={onGoLive}
                        className="rounded-lg border border-emerald-400/50 bg-emerald-500/10 px-3 py-2 text-xs font-semibold text-emerald-100 transition hover:bg-emerald-500/20"
                    >
                        Back to Live
                    </button>
                    <button
                        type="button"
                        onClick={onPlayPause}
                        className="rounded-lg border border-cyan-400/60 bg-cyan-500/10 px-3 py-2 text-xs font-semibold text-cyan-100 transition hover:bg-cyan-500/20"
                        disabled={bufferSize === 0}
                    >
                        {isPlaying ? 'Pause' : 'Play'}
                    </button>
                    <button
                        type="button"
                        onClick={() => onStep?.(-10)}
                        className="rounded-lg border border-slate-500/50 bg-slate-700/40 px-3 py-2 text-xs font-semibold text-slate-100 transition hover:bg-slate-600/50"
                        disabled={bufferSize === 0}
                    >
                        {'<< -10s'}
                    </button>
                    <button
                        type="button"
                        onClick={() => onStep?.(10)}
                        className="rounded-lg border border-slate-500/50 bg-slate-700/40 px-3 py-2 text-xs font-semibold text-slate-100 transition hover:bg-slate-600/50"
                        disabled={bufferSize === 0}
                    >
                        {'+10s >>'}
                    </button>
                    <button
                        type="button"
                        onClick={onJumpPumpOn}
                        className="rounded-lg border border-cyan-400/60 bg-cyan-500/10 px-3 py-2 text-xs font-semibold text-cyan-100 transition hover:bg-cyan-500/20 disabled:opacity-60 disabled:cursor-not-allowed"
                        disabled={bufferSize < 2}
                    >
                        Next Pump ON
                    </button>
                    <button
                        type="button"
                        onClick={onJumpPumpOff}
                        className="rounded-lg border border-cyan-400/60 bg-cyan-500/10 px-3 py-2 text-xs font-semibold text-cyan-100 transition hover:bg-cyan-500/20 disabled:opacity-60 disabled:cursor-not-allowed"
                        disabled={bufferSize < 2}
                    >
                        Next Pump OFF
                    </button>
                    <div className="flex items-center gap-2 text-[11px] text-slate-300">
                        <span className="uppercase tracking-[0.12em] text-slate-400">History</span>
                        {historyModes.map((m) => (
                            <button
                                key={m}
                                type="button"
                                onClick={() => onHistoryModeChange?.(m)}
                                className={`rounded-full border px-2.5 py-1 text-[11px] font-semibold capitalize transition ${historyMode === m ? 'border-blue-400/70 bg-blue-500/20 text-blue-100' : 'border-slate-600 bg-slate-800/60 text-slate-200 hover:border-blue-400/50 hover:text-blue-100'}`}
                            >
                                {m}
                            </button>
                        ))}
                        <button
                            type="button"
                            onClick={() => onLoadHistory?.(historyMode)}
                            className="rounded-lg border border-blue-400/60 bg-blue-500/10 px-3 py-2 text-xs font-semibold text-blue-100 transition hover:bg-blue-500/20 disabled:opacity-60 disabled:cursor-not-allowed"
                            disabled={loadingHistory}
                        >
                            {loadingHistory ? 'Loading…' : 'Load History'}
                        </button>
                    </div>
                    <button
                        type="button"
                        onClick={onClear}
                        className="rounded-lg border border-rose-400/50 bg-rose-500/10 px-3 py-2 text-xs font-semibold text-rose-100 transition hover:bg-rose-500/20"
                    >
                        Clear Buffer
                    </button>
                    <button
                        type="button"
                        onClick={onExport}
                        className="rounded-lg border border-emerald-400/60 bg-emerald-500/10 px-3 py-2 text-xs font-semibold text-emerald-100 transition hover:bg-emerald-500/20"
                    >
                        Export JSON
                    </button>
                    <input
                        ref={fileInputRef}
                        type="file"
                        accept="application/json"
                        className="hidden"
                        onChange={(e) => handleImportFile(e, onImport)}
                    />
                    <button
                        type="button"
                        onClick={() => fileInputRef.current?.click()}
                        className="rounded-lg border border-amber-400/60 bg-amber-500/10 px-3 py-2 text-xs font-semibold text-amber-100 transition hover:bg-amber-500/20"
                    >
                        Import JSON
                    </button>
                </div>

                {historyError && (
                    <div className="text-[11px] text-rose-300">{String(historyError)}</div>
                )}
                {importError && (
                    <div className="text-[11px] text-rose-300">{String(importError)}</div>
                )}
                {eventMessage && (
                    <div className="text-[11px] text-amber-200">{eventMessage}</div>
                )}

                <div className="space-y-2">
                    <div className="flex items-center justify-between text-[11px] text-slate-400">
                        <span>Timeline</span>
                        <span className="text-slate-200">{formatTime(currentTs)}</span>
                    </div>
                    <div className="relative w-full">
                        <input
                            type="range"
                            min={0}
                            max={sliderMax}
                            value={clampValue(replayIndex, sliderMax)}
                            onChange={(e) => onSeek?.(Number(e.target.value))}
                            className="w-full accent-cyan-400"
                            disabled={bufferSize === 0}
                        />
                        <div className="pointer-events-none absolute inset-0">
                            {markerMap.map((m, i) => (
                                <div
                                    key={`${m.type}-${m.index}-${i}`}
                                    className="absolute -top-3 flex flex-col items-center"
                                    style={{ left: m.left }}
                                >
                                    <button
                                        type="button"
                                        title={`${m.label || m.type} @ ${formatTime(m.ts)}`}
                                        onClick={() => onSeek?.(m.index)}
                                        className={`pointer-events-auto h-3 w-3 rounded-full border shadow-sm transition hover:scale-110 ${markerTone(m.type)}`}
                                    />
                                </div>
                            ))}
                        </div>
                    </div>
                    <div className="flex items-center justify-between text-[11px] text-slate-400">
                        <span>0</span>
                        <span>{sliderMax}</span>
                    </div>
                </div>

                <div className="mt-3 flex flex-wrap items-center gap-2 text-[10px] uppercase tracking-[0.12em] text-slate-400">
                    <span className="text-slate-300">Legend</span>
                    <LegendPill label="Pump ON" tone="bg-emerald-500/30 border-emerald-400/70 text-emerald-100" />
                    <LegendPill label="Pump OFF" tone="bg-rose-500/30 border-rose-400/70 text-rose-100" />
                    <LegendPill label="Soil Alert" tone="bg-amber-500/30 border-amber-400/70 text-amber-100" />
                    <LegendPill label="Humidity Alert" tone="bg-sky-500/30 border-sky-400/70 text-sky-100" />
                    <LegendPill label="Light Alert" tone="bg-purple-500/30 border-purple-400/70 text-purple-100" />
                </div>

                <div className="flex flex-wrap items-center gap-3">
                    <div className="text-[11px] uppercase tracking-[0.18em] text-slate-400">Speed</div>
                    <div className="flex items-center gap-2">
                        {speedOptions.map((s) => (
                            <button
                                key={s}
                                type="button"
                                onClick={() => onSpeedChange?.(s)}
                                className={`rounded-full border px-3 py-1 text-xs font-semibold transition ${speed === s ? 'border-cyan-400/70 bg-cyan-500/20 text-cyan-100' : 'border-slate-600 bg-slate-800/60 text-slate-200 hover:border-cyan-400/50 hover:text-cyan-100'}`}
                            >
                                {`${s}x`}
                            </button>
                        ))}
                    </div>
                </div>
            </div>
        </div>
    )
}

const clampValue = (v, max) => {
    if (!Number.isFinite(v)) return 0
    if (v < 0) return 0
    if (v > max) return max
    return v
}

const markerTone = (type) => {
    switch (type) {
        case 'pump-on': return 'bg-emerald-400 border-emerald-300'
        case 'pump-off': return 'bg-rose-400 border-rose-300'
        case 'soil-alert': return 'bg-amber-400 border-amber-300'
        case 'humidity-alert': return 'bg-sky-400 border-sky-300'
        case 'light-alert': return 'bg-purple-400 border-purple-300'
        default: return 'bg-slate-400 border-slate-300'
    }
}

function LegendPill({ label, tone }) {
    return (
        <span className={`inline-flex items-center gap-1 rounded-full border px-2 py-1 text-[10px] font-semibold ${tone}`}>
            <span className="h-2 w-2 rounded-full bg-white/70" />
            {label}
        </span>
    )
}

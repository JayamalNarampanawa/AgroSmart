import React, { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react'
import useAgroSmartLiveData from '../three/useAgroSmartLiveData'
import useReplayBuffer from '../hooks/useReplayBuffer'
import useReplayController from '../hooks/useReplayController'
import useReplayHistoryLoader from '../hooks/useReplayHistoryLoader'

const ReplayContext = createContext(null)

const toNumberSafe = (v, fallback = 0) => {
    const n = Number(v)
    return Number.isFinite(n) ? n : fallback
}

const parseIrrigationBool = (v) => {
    if (typeof v === 'boolean') return v
    if (typeof v === 'number') return v === 1
    if (typeof v === 'string') {
        const s = v.trim().toLowerCase()
        if (['1', 'on', 'true', 'yes'].includes(s)) return true
        if (['0', 'off', 'false', 'no'].includes(s)) return false
    }
    return false
}

const mapLiveToRaw = (live = {}) => {
    const temperature = toNumberSafe(live.temperature ?? live.Temperature, 0)
    const humidity = toNumberSafe(live.humidity ?? live.Humidity, 0)
    const soilMoisture = toNumberSafe(live.soilMoisture ?? live.SoilMoisture, 0)
    const lightLevel = toNumberSafe(live.lightLevel ?? live.LightLevel, 0)
    const irrigationOn = parseIrrigationBool(live.irrigationStatus ?? live.pumpStatus ?? live.Irrigation)
    return {
        Temperature: temperature,
        Humidity: humidity,
        SoilMoisture: soilMoisture,
        LightLevel: lightLevel,
        Irrigation: irrigationOn ? 'ON' : 'OFF',
    }
}

const mergeSnapshots = (incoming = [], existing = []) => {
    const map = new Map()
    const add = (arr) => {
        arr.forEach((s) => {
            if (!s || !Number.isFinite(s.ts)) return
            map.set(s.ts, s)
        })
    }
    add(existing)
    add(incoming)
    return Array.from(map.values()).sort((a, b) => a.ts - b.ts)
}

export function ReplayProvider({ children }) {
    const { data: liveData = {}, tick = 0 } = useAgroSmartLiveData()
    const [importError, setImportError] = useState(null)
    const liveRaw = useMemo(() => mapLiveToRaw(liveData), [liveData])
    const liveTs = liveData.__ts ?? liveData.ts ?? liveData.timestamp ?? Date.now()

    const {
        buffer,
        isRecording,
        clear,
        pause,
        resume,
        setBufferExternal,
    } = useReplayBuffer({
        source: { ...liveData, ts: liveTs, __ts: liveTs, __raw: liveRaw },
        throttleMs: 1000,
        maxPoints: 900,
        enabled: true,
    })

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
    } = useReplayController({ buffer, liveData: { ...liveData, __raw: liveRaw } })

    const { loadHistory, loading: historyLoading, error: historyErrorRaw } = useReplayHistoryLoader({ limit: 2000 })

    // Pause recording while in replay; resume in live
    useEffect(() => {
        if (mode === 'REPLAY') pause()
        else resume()
    }, [mode, pause, resume])

    const effectiveRaw = useMemo(() => {
        if (mode === 'REPLAY' && currentSnapshot?.__raw) return currentSnapshot.__raw
        return liveRaw
    }, [mode, currentSnapshot, liveRaw])

    const effectiveTick = mode === 'REPLAY' ? replayIndex : tick

    const historyError = historyErrorRaw || null

    const setSnapshots = useCallback((snapshots = []) => {
        setBufferExternal(snapshots)
        if (snapshots.length) enterReplayAtEnd()
    }, [enterReplayAtEnd, setBufferExternal])

    const loadHistoryAndReplay = useCallback(async ({ mode: loadMode = 'replace' } = {}) => {
        const incoming = await loadHistory()
        if (!Array.isArray(incoming)) return []
        const merged = loadMode === 'append' ? mergeSnapshots(incoming, buffer) : incoming
        setSnapshots(merged)
        return merged
    }, [buffer, loadHistory, setSnapshots])

    const exportBuffer = useCallback(() => {
        const blob = new Blob([JSON.stringify(buffer, null, 2)], { type: 'application/json' })
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = 'agrosmart-replay.json'
        a.click()
        URL.revokeObjectURL(url)
    }, [buffer])

    const importSnapshots = useCallback((snapshots) => {
        if (!Array.isArray(snapshots)) throw new Error('Import must be an array')
        const cleaned = snapshots
            .map((s) => {
                if (!s || !Number.isFinite(s.ts)) return null
                if (!s.__raw) return null
                const raw = s.__raw
                const r = {
                    ts: Number(s.ts),
                    temperature: toNumberSafe(s.temperature ?? raw.Temperature, 0),
                    humidity: toNumberSafe(s.humidity ?? raw.Humidity, 0),
                    soilMoisture: toNumberSafe(s.soilMoisture ?? raw.SoilMoisture, 0),
                    lightLevel: toNumberSafe(s.lightLevel ?? raw.LightLevel, 0),
                    irrigationStatus: parseIrrigationBool(s.irrigationStatus ?? s.pumpStatus ?? raw.Irrigation),
                    pumpStatus: parseIrrigationBool(s.pumpStatus ?? s.irrigationStatus ?? raw.Irrigation),
                    __raw: {
                        Temperature: toNumberSafe(raw.Temperature, 0),
                        Humidity: toNumberSafe(raw.Humidity, 0),
                        SoilMoisture: toNumberSafe(raw.SoilMoisture, 0),
                        LightLevel: toNumberSafe(raw.LightLevel, 0),
                        Irrigation: parseIrrigationBool(raw.Irrigation) ? 'ON' : 'OFF',
                    },
                    __key: s.__key || `import-${Math.random().toString(36).slice(2)}`,
                }
                return r
            })
            .filter(Boolean)
            .sort((a, b) => a.ts - b.ts)

        if (!cleaned.length) throw new Error('No valid snapshots found')
        setSnapshots(cleaned)
        return cleaned
    }, [setSnapshots])

    const handleImport = useCallback(async (snapshots) => {
        try {
            await importSnapshots(snapshots)
            setImportError(null)
        } catch (err) {
            const msg = err?.message || String(err)
            setImportError(msg)
            throw err
        }
    }, [importSnapshots])

    const value = useMemo(() => ({
        // controller state
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
        // buffer
        buffer,
        clear,
        pause,
        resume,
        isRecording,
        setBufferExternal,
        // data
        effectiveData,
        effectiveRaw,
        effectiveTick,
        currentSnapshot,
        // history
        historyLoading,
        historyError,
        loadHistoryAndReplay,
        // export/import
        exportBuffer,
        importSnapshots: handleImport,
        importError,
    }), [
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
        buffer,
        clear,
        pause,
        resume,
        isRecording,
        setBufferExternal,
        effectiveData,
        effectiveRaw,
        effectiveTick,
        currentSnapshot,
        historyLoading,
        historyError,
        loadHistoryAndReplay,
        exportBuffer,
        handleImport,
        importError,
    ])

    return (
        <ReplayContext.Provider value={value}>
            {children}
        </ReplayContext.Provider>
    )
}

export const useReplayContext = () => {
    const ctx = useContext(ReplayContext)
    if (!ctx) throw new Error('useReplay must be used within ReplayProvider')
    return ctx
}

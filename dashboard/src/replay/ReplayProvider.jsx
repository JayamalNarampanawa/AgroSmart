<<<<<<< HEAD
import React, { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState } from 'react'
=======
import React, { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react'
>>>>>>> dd9fb876adae20b81d5d7c6646bff1e2fdc10951
import useAgroSmartLiveData from '../three/useAgroSmartLiveData'
import useReplayBuffer from '../hooks/useReplayBuffer'
import useReplayController from '../hooks/useReplayController'
import useReplayHistoryLoader from '../hooks/useReplayHistoryLoader'

const ReplayContext = createContext(null)
<<<<<<< HEAD
const MAX_POINTS = 900
=======
>>>>>>> dd9fb876adae20b81d5d7c6646bff1e2fdc10951

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

<<<<<<< HEAD
const finiteOrNull = (v) => {
    const n = Number(v)
    return Number.isFinite(n) ? n : null
}

const snapshotRichness = (s = {}) => {
    const raw = s.__raw || {}
    const temp = finiteOrNull(raw.Temperature ?? s.temperature ?? s.Temperature)
    const hum = finiteOrNull(raw.Humidity ?? s.humidity ?? s.Humidity)
    const soil = finiteOrNull(raw.SoilMoisture ?? s.soilMoisture ?? s.SoilMoisture)
    const light = finiteOrNull(raw.LightLevel ?? s.lightLevel ?? s.LightLevel)
    const irrigation = raw.Irrigation ?? s.irrigationStatus ?? s.pumpStatus ?? s.Irrigation
    const finiteCount = [temp, hum, soil, light].filter((v) => v !== null && Number.isFinite(v)).length
    const hasGoodLight = Number.isFinite(light) && light > 0
    const hasIrrigation = irrigation !== undefined && irrigation !== null && String(irrigation).trim() !== ''
    return { finiteCount, hasGoodLight, hasIrrigation }
}

const pickRicherSnapshot = (a, b) => {
    if (!a) return b
    if (!b) return a
    const scoreA = snapshotRichness(a)
    const scoreB = snapshotRichness(b)
    if (scoreA.hasGoodLight !== scoreB.hasGoodLight) return scoreA.hasGoodLight ? a : b
    if (scoreA.finiteCount !== scoreB.finiteCount) return scoreA.finiteCount > scoreB.finiteCount ? a : b
    if (scoreA.hasIrrigation !== scoreB.hasIrrigation) return scoreA.hasIrrigation ? a : b
    return b
}

const mergeSnapshotsPreferRicher = (incoming = [], existing = [], cap = MAX_POINTS) => {
    const map = new Map()
    const add = (snap) => {
        if (!snap) return
        const ts = Number(snap.ts)
        if (!Number.isFinite(ts)) return
        const current = map.get(ts)
        map.set(ts, current ? pickRicherSnapshot(current, snap) : snap)
    }
    existing.forEach(add)
    incoming.forEach(add)
    const sorted = Array.from(map.values()).sort((a, b) => a.ts - b.ts)
    if (!Number.isFinite(cap) || cap <= 0) return sorted
    return sorted.slice(-cap)
=======
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
>>>>>>> dd9fb876adae20b81d5d7c6646bff1e2fdc10951
}

export function ReplayProvider({ children }) {
    const { data: liveData = {}, tick = 0 } = useAgroSmartLiveData()
    const [importError, setImportError] = useState(null)
<<<<<<< HEAD
    const [replaySource, setReplaySource] = useState('rolling')
    const [eventMessage, setEventMessage] = useState('')
    const eventTimerRef = useRef(null)
=======
>>>>>>> dd9fb876adae20b81d5d7c6646bff1e2fdc10951
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
<<<<<<< HEAD
        maxPoints: MAX_POINTS,
=======
        maxPoints: 900,
>>>>>>> dd9fb876adae20b81d5d7c6646bff1e2fdc10951
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
<<<<<<< HEAD
        setIsPlaying,
=======
>>>>>>> dd9fb876adae20b81d5d7c6646bff1e2fdc10951
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

<<<<<<< HEAD
    const clearBuffer = useCallback(() => {
        clear()
        setReplaySource('rolling')
    }, [clear])

    const loadHistoryAndReplay = useCallback(async ({ mode: loadMode = 'replace' } = {}) => {
        const incoming = await loadHistory()
        if (!Array.isArray(incoming)) return []
        const merged = loadMode === 'append'
            ? mergeSnapshotsPreferRicher(incoming, buffer, MAX_POINTS)
            : mergeSnapshotsPreferRicher(incoming, [], MAX_POINTS)
        setSnapshots(merged)
        if (merged.length) setReplaySource('firebase')
=======
    const loadHistoryAndReplay = useCallback(async ({ mode: loadMode = 'replace' } = {}) => {
        const incoming = await loadHistory()
        if (!Array.isArray(incoming)) return []
        const merged = loadMode === 'append' ? mergeSnapshots(incoming, buffer) : incoming
        setSnapshots(merged)
>>>>>>> dd9fb876adae20b81d5d7c6646bff1e2fdc10951
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

<<<<<<< HEAD
    const importSnapshots = useCallback((snapshots, { mode: importMode = 'replace' } = {}) => {
=======
    const importSnapshots = useCallback((snapshots) => {
>>>>>>> dd9fb876adae20b81d5d7c6646bff1e2fdc10951
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
<<<<<<< HEAD
        const merged = importMode === 'append'
            ? mergeSnapshotsPreferRicher(cleaned, buffer, MAX_POINTS)
            : mergeSnapshotsPreferRicher(cleaned, [], MAX_POINTS)
        setSnapshots(merged)
        setReplaySource('import')
        return merged
    }, [buffer, setSnapshots])
=======
        setSnapshots(cleaned)
        return cleaned
    }, [setSnapshots])
>>>>>>> dd9fb876adae20b81d5d7c6646bff1e2fdc10951

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

<<<<<<< HEAD
    const showEventMessage = useCallback((msg) => {
        setEventMessage(msg)
        if (eventTimerRef.current) clearTimeout(eventTimerRef.current)
        eventTimerRef.current = setTimeout(() => setEventMessage(''), 2600)
    }, [])

    useEffect(() => () => {
        if (eventTimerRef.current) clearTimeout(eventTimerRef.current)
    }, [])

    const isIrrigationOn = useCallback((snap) => (
        parseIrrigationBool(
            snap?.__raw?.Irrigation
            ?? snap?.irrigationStatus
            ?? snap?.pumpStatus
            ?? snap?.Irrigation,
        )
    ), [])

    const findNextEventIndex = useCallback((type) => {
        if (!buffer || buffer.length < 2) return -1
        const start = mode === 'REPLAY' ? replayIndex + 1 : buffer.length - 1
        const from = Math.max(1, start)
        for (let i = from; i < buffer.length; i += 1) {
            const prevOn = isIrrigationOn(buffer[i - 1])
            const curOn = isIrrigationOn(buffer[i])
            if (type === 'ON' && !prevOn && curOn) return i
            if (type === 'OFF' && prevOn && !curOn) return i
        }
        return -1
    }, [buffer, isIrrigationOn, mode, replayIndex])

    const jumpToEvent = useCallback((type) => {
        if (!buffer || buffer.length < 2) {
            showEventMessage('Not enough data to find pump events')
            return -1
        }
        const target = findNextEventIndex(type)
        if (target === -1) {
            showEventMessage(`No more Pump ${type} events in buffer`)
            return -1
        }
        setIsPlaying(false)
        seek(target)
        return target
    }, [buffer, findNextEventIndex, seek, setIsPlaying, showEventMessage])

    const jumpNextPumpOn = useCallback(() => jumpToEvent('ON'), [jumpToEvent])
    const jumpNextPumpOff = useCallback(() => jumpToEvent('OFF'), [jumpToEvent])

=======
>>>>>>> dd9fb876adae20b81d5d7c6646bff1e2fdc10951
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
<<<<<<< HEAD
        setIsPlaying,
        // buffer
        buffer,
        clear: clearBuffer,
=======
        // buffer
        buffer,
        clear,
>>>>>>> dd9fb876adae20b81d5d7c6646bff1e2fdc10951
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
<<<<<<< HEAD
        // sources & events
        replaySource,
        jumpNextPumpOn,
        jumpNextPumpOff,
        eventMessage,
=======
>>>>>>> dd9fb876adae20b81d5d7c6646bff1e2fdc10951
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
<<<<<<< HEAD
        setIsPlaying,
        buffer,
        clearBuffer,
=======
        buffer,
        clear,
>>>>>>> dd9fb876adae20b81d5d7c6646bff1e2fdc10951
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
<<<<<<< HEAD
        replaySource,
        jumpNextPumpOn,
        jumpNextPumpOff,
        eventMessage,
=======
>>>>>>> dd9fb876adae20b81d5d7c6646bff1e2fdc10951
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

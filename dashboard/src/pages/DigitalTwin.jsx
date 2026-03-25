import React, { Suspense, useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { Canvas } from '@react-three/fiber'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { motion } from 'framer-motion'
import FarmScene from '../three/FarmScene'
import useRecommendationData from '../hooks/useRecommendationData'
import useMlValidation from '../hooks/useMlValidation'
import ReplayControls from '../components/ReplayControls'
import useReplay from '../replay/useReplay'
import { calibration } from '../three/calibration'

const formatValue = (v, suffix = '') => {
  if (v === undefined || v === null || Number.isNaN(Number(v))) return '--'
  const num = Number(v)
  return `${num.toFixed(1)}${suffix}`
}

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

// Adapter to normalize any live/replay snapshot into the shape the twin expects
const mapSnapshotToTwinData = (snap = {}, fallbackRaw = {}) => {
  const raw = snap.__raw || fallbackRaw || {}
  const temperature = toNumberSafe(snap.temperature ?? snap.Temperature ?? raw.Temperature, 0)
  const humidity = toNumberSafe(snap.humidity ?? snap.Humidity ?? raw.Humidity, 0)
  const soilMoisture = toNumberSafe(snap.soilMoisture ?? snap.SoilMoisture ?? raw.SoilMoisture, 0)
  const lightLevel = toNumberSafe(snap.lightLevel ?? snap.LightLevel ?? raw.LightLevel, 0)
  const irrigationStatus = parseIrrigationBool(
    snap.irrigationStatus ?? snap.pumpStatus ?? raw.Irrigation ?? snap.Irrigation,
  )

  return {
    temperature,
    humidity,
    soilMoisture,
    lightLevel,
    irrigationStatus,
    __ts: snap.__ts ?? snap.ts ?? raw.__ts ?? null,
  }
}

// Human-friendly duration
const formatDuration = (ms = 0) => {
  if (!Number.isFinite(ms) || ms <= 0) return '—'
  const totalSeconds = Math.max(0, Math.floor(ms / 1000))
  const minutes = Math.floor(totalSeconds / 60)
  const seconds = totalSeconds % 60
  if (minutes === 0) return `${seconds}s`
  if (minutes < 60) return `${minutes}m ${seconds}s`
  const hours = Math.floor(minutes / 60)
  const remMin = minutes % 60
  return `${hours}h ${remMin}m`
}

const wait = (ms) => new Promise((resolve) => setTimeout(resolve, ms))

// Build replay insights (durations use delta between consecutive timestamps)
const buildReplayInsights = (buffer = [], markers = []) => {
  if (!Array.isArray(buffer) || buffer.length < 2) {
    return {
      totalDurationMs: 0,
      pumpOnCount: 0,
      pumpOffCount: 0,
      anomalies: 0,
      longestPumpOnMs: 0,
      pumpOnTotalMs: 0,
      dryMs: 0,
      humidityAlertMs: 0,
      lightAlertMs: 0,
      firstTs: null,
      lastTs: null,
      narrative: [],
    }
  }

  let pumpOnCount = 0
  let pumpOffCount = 0
  let anomalies = markers.filter((m) => m.type?.includes('alert')).length
  let longestPumpOnMs = 0
  let pumpOnTotalMs = 0
  let dryMs = 0
  let humidityAlertMs = 0
  let lightAlertMs = 0
  let firstTs = null
  let lastTs = null

  let onStart = null

  for (let i = 0; i < buffer.length - 1; i += 1) {
    const a = buffer[i]
    const b = buffer[i + 1]
    const twinA = mapSnapshotToTwinData(a, a.__raw || {})
    const twinB = mapSnapshotToTwinData(b, b.__raw || {})
    const tsA = a.ts ?? a.__ts ?? twinA.__ts
    const tsB = b.ts ?? b.__ts ?? twinB.__ts
    if (!Number.isFinite(tsA) || !Number.isFinite(tsB) || tsB <= tsA) continue
    const delta = tsB - tsA

    if (firstTs === null || tsA < firstTs) firstTs = tsA
    if (lastTs === null || tsB > lastTs) lastTs = tsB

    const pump = parseIrrigationBool(a.irrigationStatus ?? a.pumpStatus ?? a.Irrigation ?? a.__raw?.Irrigation)
    const nextPump = parseIrrigationBool(b.irrigationStatus ?? b.pumpStatus ?? b.Irrigation ?? b.__raw?.Irrigation)
    if (pump && !onStart) onStart = tsA
    if (pump) pumpOnTotalMs += delta
    if (pump && !nextPump && onStart) {
      const span = tsB - onStart
      longestPumpOnMs = Math.max(longestPumpOnMs, span)
      onStart = null
      pumpOffCount += 1
    }
    if (!pump && nextPump) pumpOnCount += 1

    // Conditions from twin/normalized
    const wetness = a?.normalized?.wetness ?? a?.normalized?.soil ?? null
    const brightness = a?.normalized?.brightness ?? a?.normalized?.light ?? null
    const soil = toNumberSafe(twinA.soilMoisture, 0)
    const hum = toNumberSafe(twinA.humidity, 0)
    const light = toNumberSafe(twinA.lightLevel, 0)

    const soilAlert = (Number.isFinite(wetness) && wetness < 0.32) || soil >= 3200
    const humAlert = hum <= 25 || hum >= 85
    const lightAlert = light <= 200 || light >= 3600 || (Number.isFinite(brightness) && brightness > 0.9)

    if (soilAlert) dryMs += delta
    if (humAlert) humidityAlertMs += delta
    if (lightAlert) lightAlertMs += delta
  }

  const totalDurationMs = firstTs && lastTs ? Math.max(0, lastTs - firstTs) : 0
  const narrative = []
  if (pumpOnCount > 0) narrative.push('Pump activity was concentrated within the session; markers highlight ON/OFF points.')
  if (dryMs > pumpOnTotalMs) narrative.push('Soil spent longer in dry stress than in irrigated periods.')
  if (humidityAlertMs < dryMs && humidityAlertMs > 0) narrative.push('Humidity alerts were shorter compared to soil stress duration.')

  return {
    totalDurationMs,
    pumpOnCount,
    pumpOffCount,
    anomalies,
    longestPumpOnMs,
    pumpOnTotalMs,
    dryMs,
    humidityAlertMs,
    lightAlertMs,
    firstTs,
    lastTs,
    narrative,
  }
}

// Build short, deterministic observation captions from insights/markers/current state
const buildObservationCaptions = ({ mode, insights, markers = [], currentSnapshot = {}, sensorData = {}, states = {} }) => {
  const obs = []
  const pumpOnCount = insights?.pumpOnCount ?? 0
  const anomalies = insights?.anomalies ?? 0
  const totalMs = insights?.totalDurationMs ?? 0
  const dryMs = insights?.dryMs ?? 0
  const humidityMs = insights?.humidityAlertMs ?? 0
  const lightMs = insights?.lightAlertMs ?? 0
  const pumpOnTotalMs = insights?.pumpOnTotalMs ?? 0
  const longestOn = insights?.longestPumpOnMs ?? 0

  const alertMarkers = markers.filter((m) => m.type?.includes('alert')).length
  const pumpMarkers = markers.filter((m) => m.type === 'pump-on' || m.type === 'pump-off').length

  if (mode === 'REPLAY') {
    if (anomalies === 0) {
      obs.push('Replay shows stable conditions with no detected anomalies.')
    } else {
      if (dryMs > pumpOnTotalMs * 1.2) obs.push('Soil stress lasted longer than irrigated periods in this replay.')
      if (humidityMs > 0 && humidityMs < dryMs) obs.push('Humidity alerts were brief compared to soil stress duration.')
      if (lightMs > humidityMs && lightMs > dryMs) obs.push('Light variation contributed the most alert time in this replay.')
      if (anomalies > 0 && totalMs > 0 && anomalies / Math.max(1, (totalMs / 600000)) > 0.8) {
        obs.push('Anomalies were moderately concentrated across the session timeline.')
      }
      if (alertMarkers > pumpMarkers + 2) obs.push('Alerts outnumbered pump events, suggesting conditions were unstable.')
    }

    if (pumpOnCount <= 1 && totalMs > 0) obs.push('Pump activity was limited relative to the replay duration.')
    if (pumpMarkers > 0 && longestOn > 0) obs.push(`Longest pump ON segment was ${formatDuration(longestOn)}.`)
    if (pumpOnTotalMs > 0 && dryMs > pumpOnTotalMs && anomalies > 0) obs.push('Pump activity did not fully offset soil stress across the replay.')
  } else {
    const soil = sensorData?.soilMoisture
    const humidity = sensorData?.humidity
    const light = sensorData?.lightLevel
    const irrigation = sensorData?.irrigationStatus
    if (irrigation) obs.push('Irrigation is currently active.')
    if (states?.soil) obs.push(`Current soil state: ${states.soil}.`)
    if (Number.isFinite(soil) && soil >= 3200) obs.push('Soil moisture is currently in a dry range.')
    if (Number.isFinite(humidity) && (humidity <= 25 || humidity >= 85)) obs.push('Humidity is currently outside the preferred range.')
    if (Number.isFinite(light) && (light <= 200 || light >= 3600)) obs.push('Light level is currently outside the target band.')
    if (!obs.length) obs.push('Live conditions appear stable at this moment.')
  }

  // Ensure 2–5 items max; add a stability note if list is too short
  if (obs.length === 1) obs.push(mode === 'REPLAY' ? 'Overall replay appears steady aside from noted items.' : 'Monitoring shows no additional alerts right now.')
  if (obs.length > 5) return obs.slice(0, 5)
  return obs
}

// Derive pump and anomaly markers from replay buffer
const buildReplayMarkers = (buffer = []) => {
  if (!Array.isArray(buffer) || buffer.length === 0) return { markers: [], summary: { pumpOn: 0, pumpOff: 0, anomalies: 0, firstTs: null, lastTs: null } }

  const markers = []
  let prevPump = null
  let pumpOn = 0
  let pumpOff = 0
  let anomalies = 0
  let firstTs = null
  let lastTs = null

  const pushMarker = (m) => {
    markers.push(m)
    if (!firstTs || (m.ts && m.ts < firstTs)) firstTs = m.ts
    if (!lastTs || (m.ts && m.ts > lastTs)) lastTs = m.ts
  }

  buffer.forEach((snap, idx) => {
    const twin = mapSnapshotToTwinData(snap, snap.__raw || {})
    const ts = snap.ts ?? snap.__ts ?? twin.__ts ?? null
    const pump = parseIrrigationBool(snap.irrigationStatus ?? snap.pumpStatus ?? snap.Irrigation ?? snap.__raw?.Irrigation)

    if (prevPump === false && pump === true) {
      pumpOn += 1
      pushMarker({ index: idx, ts, type: 'pump-on', label: 'Pump ON' })
    }
    if (prevPump === true && pump === false) {
      pumpOff += 1
      pushMarker({ index: idx, ts, type: 'pump-off', label: 'Pump OFF' })
    }
    prevPump = pump

    // Anomaly detection (lightweight): fall back to raw values if severity not provided
    const wetness = snap?.normalized?.wetness ?? snap?.normalized?.soil ?? null
    const brightness = snap?.normalized?.brightness ?? snap?.normalized?.light ?? null
    const soil = toNumberSafe(twin.soilMoisture, 0)
    const hum = toNumberSafe(twin.humidity, 0)
    const light = toNumberSafe(twin.lightLevel, 0)

    const soilAlert = (Number.isFinite(wetness) && wetness < 0.32) || soil >= 3200
    const humAlert = hum <= 25 || hum >= 85
    const lightAlert = light <= 200 || light >= 3600 || (Number.isFinite(brightness) && brightness > 0.9)

    if (soilAlert) {
      anomalies += 1
      pushMarker({ index: idx, ts, type: 'soil-alert', label: 'Soil Alert' })
    }
    if (humAlert) {
      anomalies += 1
      pushMarker({ index: idx, ts, type: 'humidity-alert', label: 'Humidity Alert' })
    }
    if (lightAlert) {
      anomalies += 1
      pushMarker({ index: idx, ts, type: 'light-alert', label: 'Light Alert' })
    }
  })

  return {
    markers,
    summary: {
      pumpOn,
      pumpOff,
      anomalies,
      firstTs,
      lastTs,
    },
  }
}

export default function DigitalTwin() {
  const recommendation = useRecommendationData()
  const { mlResult } = useMlValidation(recommendation)
  const navigate = useNavigate()
  const [params] = useSearchParams()
  const [historyMode, setHistoryMode] = useState('replace')
  const [presentationMode, setPresentationMode] = useState(false)
  const [presentationStatus, setPresentationStatus] = useState('')
  const [presentationHighlight, setPresentationHighlight] = useState('')
  const presentationController = useRef({ cancelled: false, timers: [] })
  const [cameraKey, setCameraKey] = useState('overview')

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
    buffer,
    clear,
    loadHistoryAndReplay,
    historyLoading,
    historyError,
    isRecording,
    effectiveData,
    effectiveRaw,
    effectiveTick,
    currentSnapshot,
    replaySource,
    jumpNextPumpOn,
    jumpNextPumpOff,
    eventMessage,
    importSnapshots,
    exportBuffer,
    importError,
    liveData = {},
    liveConnected = false,
    liveError = null,
    liveNormalized = {},
    liveStates = {},
  } = useReplay()

  const debugMode = params.get('debug') === '1'
  const labelsEnabled = params.get('labels') === '1'

  const computeWetnessRaw = useMemo(() => {
    const span = Math.max(calibration.soil.dry - calibration.soil.wet, 1)
    return (val) => {
      const safeVal = Number.isFinite(val) ? val : calibration.soil.dry
      return Math.max(0, Math.min(1, (calibration.soil.dry - safeVal) / span))
    }
  }, [])

  const cameraTargets = useMemo(() => ({
    overview: { position: [6, 3.6, 8], lookAt: [0, 0.6, 0], label: 'Farm overview' },
    soil: { position: [2.4, 2.1, 2.4], lookAt: [0, 0.4, 0], label: 'Soil zone' },
    sensorPole: { position: [-1.4, 2.5, 2.2], lookAt: [0, 0.9, 0], label: 'Sensor pole' },
    pump: { position: [-2.8, 1.6, 3.2], lookAt: [0, 0.6, 0], label: 'Pump area' },
    replayOverview: { position: [7, 4.2, -7], lookAt: [0, 0.6, 0], label: 'Replay overview' },
  }), [])

  const computeBrightnessRaw = useMemo(() => {
    const span = Math.max(calibration.light.dark - calibration.light.bright, 1)
    return (val) => {
      const safeVal = Number.isFinite(val) ? val : calibration.light.dark
      return Math.max(0, Math.min(1, (calibration.light.dark - safeVal) / span))
    }
  }, [])

  const handleLoadHistory = useCallback(async (modeSelected) => {
    await loadHistoryAndReplay({ mode: modeSelected })
  }, [loadHistoryAndReplay])

  const stopPresentation = () => {
    presentationController.current.cancelled = true
    presentationController.current.timers.forEach(clearTimeout)
    presentationController.current = { cancelled: false, timers: [] }
    setPresentationHighlight('')
    setPresentationStatus('')
    setCameraKey('overview')
  }

  const baseSnapshot = mode === 'REPLAY'
    ? (currentSnapshot || effectiveData || {})
    : (effectiveData || liveData || {})

  const sensorData = useMemo(() => mapSnapshotToTwinData(baseSnapshot, effectiveRaw), [baseSnapshot, effectiveRaw])
  const effectiveNormalized = baseSnapshot.normalized || liveNormalized || {}
  const effectiveStates = baseSnapshot.states || liveStates || {}
  const effectiveIrrigationOn = Boolean(sensorData?.irrigationStatus)
  const rawForDebug = effectiveRaw || baseSnapshot.__raw || {}
  const timelineTs = baseSnapshot.ts ?? baseSnapshot.__ts ?? effectiveRaw?.ts ?? effectiveRaw?.__ts ?? null
  const liveLabel = liveData?.__ts ? new Date(liveData.__ts).toLocaleTimeString([], { hour12: false }) : null

  const { markers, summary } = useMemo(() => buildReplayMarkers(buffer), [buffer])
  const insights = useMemo(() => buildReplayInsights(buffer, markers), [buffer, markers])
  const observations = useMemo(
    () => buildObservationCaptions({ mode, insights, markers, currentSnapshot: baseSnapshot, sensorData, states: effectiveStates }),
    [mode, insights, markers, baseSnapshot, sensorData, effectiveStates],
  )
  const activeCameraTarget = cameraTargets[cameraKey] || cameraTargets.overview

  useEffect(() => {
    if (!presentationMode) {
      stopPresentation()
      return
    }

    let active = true
    presentationController.current.cancelled = false

    const runDemo = async () => {
      setPresentationStatus('Preparing presentation...')

      if (mode !== 'REPLAY') {
        if (buffer.length < 2) await handleLoadHistory(historyMode)
      }

      // Ensure data is ready
      const readyBuffer = buffer.length ? buffer : []
      if (!readyBuffer.length) {
        setPresentationStatus('No replay data available for demo.')
        return
      }

      // Pause any active playback to avoid conflicts
      if (isPlaying) togglePlay()

      // Start at the beginning
      seek(0)
      setCameraKey('overview')
      setPresentationHighlight('timeline')
      setPresentationStatus('Starting guided replay...')
      await wait(900)
      if (!active || presentationController.current.cancelled) return

      const importantMarkers = markers
        .filter((m) => ['pump-on', 'pump-off', 'soil-alert', 'humidity-alert', 'light-alert'].includes(m.type))
        .sort((a, b) => (a.ts || a.index || 0) - (b.ts || b.index || 0))
      const steps = importantMarkers.slice(0, 6)

      for (const m of steps) {
        if (!active || presentationController.current.cancelled) break
        setPresentationHighlight('timeline')
        setPresentationStatus(m.label ? `Showing ${m.label.toLowerCase()}` : 'Highlighting timeline event')
        if (m.type === 'pump-on' || m.type === 'pump-off') setCameraKey('pump')
        else if (m.type === 'soil-alert') setCameraKey('soil')
        else setCameraKey('sensorPole')
        if (Number.isFinite(m.index)) seek(m.index)
        await wait(1200)
      }

      if (active && !presentationController.current.cancelled) {
        setCameraKey('replayOverview')
        setPresentationHighlight('insights')
        setPresentationStatus('Reviewing replay insights')
        await wait(1400)
      }

      if (active && !presentationController.current.cancelled) {
        setCameraKey('overview')
        setPresentationHighlight('observations')
        setPresentationStatus('Summarizing monitoring observations')
        await wait(1400)
      }

      if (active && !presentationController.current.cancelled) {
        setPresentationStatus('Presentation complete. You can take over controls.')
        setPresentationHighlight('')
        setCameraKey('overview')
      }
    }

    runDemo()

    return () => {
      active = false
      stopPresentation()
    }
  }, [presentationMode, buffer, historyMode, handleLoadHistory, isPlaying, markers, mode, seek, togglePlay])

  const statusTone = liveConnected ? 'bg-emerald-500/30 border-emerald-400/50 text-emerald-100' : 'bg-amber-500/20 border-amber-400/40 text-amber-100'
  const irrigationLabel = effectiveIrrigationOn ? 'ON' : 'OFF'

  return (
    <div className="fixed inset-0 w-screen h-screen overflow-hidden bg-black text-slate-100">
      <div className="absolute inset-0 pointer-events-none bg-gradient-to-b from-black via-[#050912] to-black opacity-90" />

      <div className="absolute top-0 left-0 right-0 z-20 flex items-center justify-between px-6 md:px-12 py-4 bg-black/40 backdrop-blur-xl border-b border-white/10 shadow-[0_10px_40px_-24px_rgba(16,185,129,0.45)]">
        <div>
          <div className="text-[11px] uppercase tracking-[0.35em] text-emerald-200/80">AgroSmart 2.0</div>
          <div className="text-xl font-semibold text-white">Digital Twin Hologram</div>
        </div>
        <button
          onClick={() => navigate('/dashboard')}
          className="rounded-full bg-gradient-to-r from-emerald-400 to-cyan-300 px-5 py-2.5 text-sm font-semibold text-emerald-950 shadow-[0_10px_40px_-18px_rgba(6,182,212,0.75)] transition hover:translate-y-[-1px] focus:outline-none focus:ring-2 focus:ring-emerald-200/70 focus:ring-offset-2 focus:ring-offset-black"
        >
          Go to Dashboard
        </button>
      </div>

      <Canvas
        className="absolute inset-0"
        shadows
        camera={{ position: [6, 3.6, 8], fov: 52 }}
        gl={{ antialias: true, powerPreference: 'high-performance' }}
      >
        <Suspense fallback={null}>
          <FarmScene
            data={sensorData}
            normalized={effectiveNormalized}
            irrigationOn={effectiveIrrigationOn}
            tick={effectiveTick}
            debugMode={debugMode}
            labelsEnabled={labelsEnabled}
            recommendation={recommendation}
            mlResult={mlResult}
            cameraTarget={activeCameraTarget}
          />
        </Suspense>
      </Canvas>

      <div className="relative z-10 flex h-full flex-col justify-between">
        <motion.div
          initial={{ opacity: 0, y: -12 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, ease: 'easeOut' }}
          className="px-6 pt-8 md:px-12"
        >
          <div className="text-xs uppercase tracking-[0.35em] text-emerald-200/80">AgroSmart 2.0</div>
          <h1 className="mt-3 text-3xl md:text-4xl font-semibold text-white">Digital Twin</h1>
          <p className="mt-2 max-w-3xl text-sm text-slate-200/90">AR-Enhanced Hybrid IoT Monitoring · Cinematic hologram of your live farm state. Read-only, monitoring-first.</p>
          <div className="mt-4 flex flex-wrap items-center gap-3 text-[11px] font-semibold">
            <div className="relative flex items-center gap-2">
              <span className="relative inline-flex h-3.5 w-3.5">
                <span key={effectiveTick} className="absolute inline-flex h-3.5 w-3.5 animate-ping rounded-full bg-cyan-300 opacity-70" />
                <span className="relative inline-flex h-3.5 w-3.5 rounded-full bg-cyan-200 shadow-[0_0_12px_rgba(34,211,238,0.9)]" />
              </span>
              <span className="text-cyan-100">{mode === 'LIVE' ? 'LIVE' : 'REPLAY'}</span>
              <span className="rounded-full border border-cyan-400/60 bg-cyan-500/15 px-2.5 py-0.5 text-[10px] text-cyan-100 shadow-[0_8px_24px_-14px_rgba(59,130,246,0.55)]">
                {replaySource === 'firebase' ? 'Firebase History' : replaySource === 'import' ? 'Imported' : 'Rolling Buffer'}
              </span>
              <span className="rounded-full border border-slate-500/50 bg-slate-900/70 px-2.5 py-0.5 text-[10px] text-slate-100">
                Tick {effectiveTick}
              </span>
              {eventMessage && (
                <span className="rounded-full border border-amber-400/60 bg-amber-500/15 px-2.5 py-0.5 text-[10px] text-amber-100 shadow-[0_8px_24px_-14px_rgba(251,191,36,0.55)]">
                  {eventMessage}
                </span>
              )}
            </div>
            <div className={`inline-flex items-center rounded-full border px-3 py-1 backdrop-blur ${statusTone}`}>
              <span className={`mr-2 h-2 w-2 rounded-full ${liveConnected ? 'bg-emerald-300 shadow-[0_0_10px_#34d399]' : 'bg-amber-300'}`} />
              {liveConnected ? 'Connected to Firebase' : 'Waiting for live data...'}
            </div>
            {!liveConnected && (
              <span className="rounded-full bg-rose-500/10 px-3 py-1 text-rose-200 border border-rose-400/50 shadow-[0_8px_24px_-14px_rgba(248,113,113,0.45)]">Live disconnected</span>
            )}
            {liveError && (
              <span className="rounded-full bg-amber-500/10 px-3 py-1 text-amber-200 border border-amber-400/40 shadow-[0_8px_24px_-14px_rgba(251,191,36,0.4)]">Listener issue</span>
            )}
          </div>

          <div className="mt-5 flex flex-col gap-3 max-w-4xl">
            <div className="flex flex-wrap items-center gap-3 text-xs">
              <button
                onClick={() => {
                  setPresentationMode((prev) => {
                    if (prev) stopPresentation()
                    return !prev
                  })
                }}
                className={`rounded-full border px-3 py-1.5 font-semibold transition ${presentationMode ? 'border-emerald-400/70 bg-emerald-500/20 text-emerald-100 shadow-[0_10px_30px_-12px_rgba(16,185,129,0.55)]' : 'border-slate-500/70 bg-slate-900/70 text-slate-100 hover:border-emerald-400/60 hover:text-emerald-100'}`}
              >
                {presentationMode ? 'Stop Presentation' : 'Presentation Mode'}
              </button>
              {presentationMode && (
                <span className="text-emerald-100/90 flex items-center gap-2 bg-emerald-500/10 border border-emerald-400/40 px-3 py-1 rounded-full shadow-[0_8px_24px_-14px_rgba(16,185,129,0.35)]">
                  {presentationStatus || 'Guided demo running...'}
                  {activeCameraTarget?.label && (
                    <span className="rounded-full border border-emerald-400/60 bg-emerald-500/20 px-2 py-0.5 text-[10px] text-emerald-100">
                      {activeCameraTarget.label}
                    </span>
                  )}
                </span>
              )}
            </div>

            <div className={`${presentationHighlight === 'timeline' ? 'ring-2 ring-emerald-400/70 shadow-[0_0_30px_rgba(16,185,129,0.25)] scale-[1.005]' : ''} transition rounded-2xl`}> 
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
                loadingHistory={historyLoading}
                historyError={historyError?.message || historyError}
                historyMode={historyMode}
                onHistoryModeChange={setHistoryMode}
                onExport={exportBuffer}
                onImport={importSnapshots}
                importError={importError}
                isRecording={isRecording}
                liveLabel={liveLabel}
                timestamp={timelineTs}
                replaySource={replaySource}
                onJumpPumpOn={jumpNextPumpOn}
                onJumpPumpOff={jumpNextPumpOff}
                eventMessage={eventMessage}
                markers={markers}
              />
            </div>

            {historyLoading && (
              <div className="rounded-2xl border border-cyan-400/40 bg-cyan-500/10 px-4 py-3 text-sm text-cyan-50 shadow-[0_0_24px_rgba(34,211,238,0.2)]">
                Loading replay history…
              </div>
            )}
            {!historyLoading && mode === 'REPLAY' && buffer.length === 0 && (
              <div className="rounded-2xl border border-slate-500/40 bg-slate-900/70 px-4 py-3 text-sm text-slate-100 shadow-[0_0_20px_rgba(148,163,184,0.2)]">
                No replay data loaded. Import a buffer or fetch history to begin the tour.
              </div>
            )}
          </div>

          <div className="mt-4 flex flex-wrap items-center gap-3 text-[11px] text-slate-200">
            <div className="rounded-xl border border-cyan-400/30 bg-cyan-500/10 px-3 py-2 shadow-[0_0_20px_rgba(34,211,238,0.22)]">
              Pump activations: <span className="font-semibold text-cyan-100">{summary.pumpOn}</span> · offs: <span className="font-semibold text-cyan-100">{summary.pumpOff}</span>
            </div>
            <div className="rounded-xl border border-amber-400/30 bg-amber-500/10 px-3 py-2 shadow-[0_0_20px_rgba(251,191,36,0.22)]">
              Anomalies detected: <span className="font-semibold text-amber-100">{summary.anomalies}</span>
            </div>
            {summary.firstTs && (
              <div className="rounded-xl border border-slate-500/40 bg-slate-900/70 px-3 py-2 text-slate-100 shadow-[0_0_18px_rgba(148,163,184,0.2)]">
                Range: {new Date(summary.firstTs).toLocaleTimeString([], { hour12: false })} → {new Date(summary.lastTs || summary.firstTs).toLocaleTimeString([], { hour12: false })}
              </div>
            )}
          </div>

          <div className={`mt-5 grid grid-cols-2 gap-3 md:grid-cols-3 lg:grid-cols-4 text-slate-200 text-sm transition ${presentationHighlight === 'insights' ? 'ring-2 ring-cyan-400/60 shadow-[0_0_28px_rgba(56,189,248,0.25)] scale-[1.005] rounded-2xl px-2 py-2' : ''}`}>
            <InsightCard label="Replay Duration" value={formatDuration(insights.totalDurationMs)} tone="border-cyan-400/40 bg-cyan-500/10 text-cyan-100" />
            <InsightCard label="Pump ON events" value={insights.pumpOnCount} tone="border-emerald-400/40 bg-emerald-500/10 text-emerald-100" />
            <InsightCard label="Pump OFF events" value={insights.pumpOffCount} tone="border-rose-400/40 bg-rose-500/10 text-rose-100" />
            <InsightCard label="Longest pump ON" value={formatDuration(insights.longestPumpOnMs)} tone="border-emerald-400/40 bg-emerald-500/10 text-emerald-100" />
            <InsightCard label="Dry soil time" value={formatDuration(insights.dryMs)} tone="border-amber-400/40 bg-amber-500/10 text-amber-100" />
            <InsightCard label="Humidity alert time" value={formatDuration(insights.humidityAlertMs)} tone="border-sky-400/40 bg-sky-500/10 text-sky-100" />
            <InsightCard label="Light alert time" value={formatDuration(insights.lightAlertMs)} tone="border-purple-400/40 bg-purple-500/10 text-purple-100" />
            <InsightCard label="Total anomalies" value={insights.anomalies} tone="border-amber-400/40 bg-amber-500/10 text-amber-100" />
          </div>

          {insights.narrative.length > 0 && (
            <div className="mt-4 rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-[12px] text-slate-100 shadow-lg shadow-cyan-500/5 backdrop-blur">
              <div className="text-[11px] uppercase tracking-[0.2em] text-slate-300 mb-1">Replay Insights</div>
              <ul className="list-disc pl-4 space-y-1 marker:text-cyan-300">
                {insights.narrative.map((line, i) => (
                  <li key={i}>{line}</li>
                ))}
              </ul>
            </div>
          )}

          {observations.length > 0 && (
            <div className={`mt-4 rounded-2xl border border-emerald-400/20 bg-emerald-500/5 px-4 py-3 text-[12px] text-emerald-50 shadow-lg shadow-emerald-500/10 backdrop-blur transition ${presentationHighlight === 'observations' ? 'ring-2 ring-emerald-400/60 shadow-[0_0_28px_rgba(16,185,129,0.25)] scale-[1.005]' : ''}`}>
              <div className="text-[11px] uppercase tracking-[0.2em] text-emerald-200/90 mb-1">Smart Observations</div>
              <ul className="list-disc pl-4 space-y-1 marker:text-emerald-300">
                {observations.map((line, i) => (
                  <li key={i}>{line}</li>
                ))}
              </ul>
            </div>
          )}
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 18 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.9, ease: 'easeOut', delay: 0.1 }}
          className="px-6 pb-12 md:px-12"
        >
          <div className="grid grid-cols-2 gap-3 md:grid-cols-4">
            <MetricCard label="Temperature" value={formatValue(sensorData.temperature, '°C')} stateLabel={effectiveStates.temp} tone={toneForState(effectiveStates.temp)} />
            <MetricCard label="Humidity" value={formatValue(sensorData.humidity, '%')} tone="slate" />
            <MetricCard label="Soil Moisture" value={formatValue(sensorData.soilMoisture, '')} stateLabel={effectiveStates.soil} tone={toneForState(effectiveStates.soil)} />
            <MetricCard label="Light" value={formatValue(sensorData.lightLevel, '')} stateLabel={effectiveStates.light} tone={toneForState(effectiveStates.light)} />
          </div>

          <div className="mt-5 flex items-center justify-between gap-4 flex-col md:flex-row">
            <div className="w-full md:w-auto rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-sm text-slate-200 shadow-lg shadow-emerald-500/5 backdrop-blur flex items-center gap-2">
              Irrigation Status:
              <span className={`rounded-full border px-2 py-1 text-xs font-semibold ${toneForState(effectiveStates?.irrigation ? 'ON' : 'OFF')}`}>{irrigationLabel}</span>
            </div>
            <button
              onClick={() => navigate('/dashboard')}
              className="w-full md:w-auto rounded-full bg-emerald-500 px-6 py-3 text-center text-sm font-semibold text-emerald-950 shadow-[0_10px_40px_-12px_rgba(16,185,129,0.6)] transition hover:translate-y-[-1px] hover:bg-emerald-400 focus:outline-none focus:ring-2 focus:ring-emerald-300 focus:ring-offset-2 focus:ring-offset-black"
            >
              Enter Dashboard
            </button>
          </div>
        </motion.div>

        {debugMode && (
          <div className="absolute bottom-4 right-4 z-20 w-full max-w-md rounded-2xl border border-white/10 bg-black/80 p-4 text-xs text-slate-100 shadow-2xl backdrop-blur-md space-y-3">
            <div className="flex items-center justify-between">
              <div className="font-semibold text-emerald-200">Debug Overlay</div>
              <div className="text-[10px] text-slate-400">Local only · read-only</div>
            </div>
            <div className="grid grid-cols-2 gap-2">
              <DebugRow label="soilRaw" value={formatValue(rawForDebug.soilMoisture, '')} />
              <DebugRow label="wetness" value={effectiveNormalized.wetness?.toFixed(3)} />
              <DebugRow label="soilState" value={effectiveStates.soil} />
              <DebugRow label="lightRaw" value={formatValue(rawForDebug.lightLevel, '')} />
              <DebugRow label="brightness" value={effectiveNormalized.brightness?.toFixed(3)} />
              <DebugRow label="lightState" value={effectiveStates.light} />
              <DebugRow label="temp" value={formatValue(rawForDebug.temperature, '°C')} />
              <DebugRow label="humidity" value={formatValue(rawForDebug.humidity, '%')} />
              <DebugRow label="irrigationOn" value={effectiveIrrigationOn ? 'true' : 'false'} />
            </div>

            <div className="space-y-2">
              <Bar label="Wetness" value={effectiveNormalized.wetness} raw={computeWetnessRaw(rawForDebug.soilMoisture)} />
              <Bar label="Brightness" value={effectiveNormalized.brightness} raw={computeBrightnessRaw(rawForDebug.lightLevel)} />
            </div>

            <div className="flex items-center justify-between text-lg font-bold">
              <span className={`${effectiveStates.soil === 'Wet' ? 'text-sky-200' : 'text-amber-200'}`}>{effectiveStates.soil === 'Wet' ? 'WET' : 'DRY'}</span>
              <span className={`${effectiveStates.light === 'High' ? 'text-yellow-200' : 'text-slate-200'}`}>{effectiveStates.light === 'High' ? 'BRIGHT' : 'DARK'}</span>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}

function MetricCard({ label, value, stateLabel, tone = 'text-slate-200 border-slate-500/40 bg-slate-500/10' }) {
  return (
    <div className={`rounded-2xl border border-white/10 bg-white/5 px-4 py-3 shadow-lg shadow-sky-500/5 backdrop-blur`}> 
      <div className="text-[11px] uppercase tracking-[0.2em] text-slate-300">{label}</div>
      <div className="mt-1 flex items-baseline gap-2 text-xl font-semibold text-white">
        <span>{value}</span>
        {stateLabel && (
          <span className={`rounded-full border px-2 py-0.5 text-[11px] font-semibold ${tone}`}>{stateLabel}</span>
        )}
      </div>
    </div>
  )
}

function toneForState(state) {
  switch (state) {
    case 'Dry': return 'text-amber-200 border-amber-500/40 bg-amber-500/10'
    case 'Optimal': return 'text-emerald-200 border-emerald-500/40 bg-emerald-500/10'
    case 'Wet': return 'text-sky-200 border-sky-500/40 bg-sky-500/10'
    case 'Hot': return 'text-orange-200 border-orange-500/40 bg-orange-500/10'
    case 'Cool': return 'text-sky-200 border-sky-500/40 bg-sky-500/10'
    case 'High': return 'text-sky-200 border-sky-500/40 bg-sky-500/10'
    case 'Low': return 'text-amber-200 border-amber-500/40 bg-amber-500/10'
    case 'ON': return 'text-cyan-200 border-cyan-500/40 bg-cyan-500/10'
    case 'OFF': return 'text-slate-200 border-slate-500/40 bg-slate-500/10'
    default: return 'text-slate-200 border-slate-500/40 bg-slate-500/10'
  }
}

function DebugRow({ label, value }) {
  return (
    <div className="flex justify-between gap-2"><span className="text-slate-400">{label}</span><span className="font-semibold text-white">{value}</span></div>
  )
}

function Bar({ label, value = 0, raw = 0 }) {
  const safeVal = Number.isFinite(value) ? Math.max(0, Math.min(1, value)) : 0
  const safeRaw = Number.isFinite(raw) ? Math.max(0, Math.min(1, raw)) : 0
  return (
    <div className="space-y-1">
      <div className="flex justify-between text-[11px] text-slate-300">
        <span>{label}</span>
        <span className="text-slate-100">{safeVal.toFixed(3)} (smoothed) · raw {safeRaw.toFixed(3)}</span>
      </div>
      <div className="relative h-2 w-full overflow-hidden rounded-full bg-slate-800">
        <div className="absolute inset-0 bg-slate-700" style={{ width: `${safeRaw * 100}%`, opacity: 0.4 }} />
        <div className="absolute inset-0 bg-emerald-400" style={{ width: `${safeVal * 100}%` }} />
      </div>
    </div>
  )
}

function InsightCard({ label, value, tone }) {
  return (
    <div className={`rounded-2xl border px-3 py-3 text-sm font-semibold shadow-lg shadow-cyan-500/8 backdrop-blur ${tone}`}>
      <div className="text-[11px] uppercase tracking-[0.18em] text-slate-200">{label}</div>
      <div className="mt-1 text-lg text-white">{value}</div>
    </div>
  )
}

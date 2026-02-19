import React, { Suspense } from 'react'
import { Canvas } from '@react-three/fiber'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { motion } from 'framer-motion'
import FarmScene from '../three/FarmScene'
import useAgroSmartLiveData from '../three/useAgroSmartLiveData'

const formatValue = (v, suffix = '') => {
  if (v === undefined || v === null || Number.isNaN(Number(v))) return '--'
  const num = Number(v)
  return `${num.toFixed(1)}${suffix}`
}

export default function DigitalTwin() {
  const { data, raw, normalized, states, irrigationOn, connected, error, tick, calibration } = useAgroSmartLiveData()
  const navigate = useNavigate()
  const [params] = useSearchParams()

  const statusTone = connected ? 'bg-emerald-500/30 border-emerald-400/50 text-emerald-100' : 'bg-amber-500/20 border-amber-400/40 text-amber-100'
  const irrigationLabel = irrigationOn ? 'ON' : 'OFF'

  return (
    <div className="fixed inset-0 w-screen h-screen overflow-hidden bg-black text-slate-100">
      <div className="absolute inset-0 pointer-events-none bg-gradient-to-b from-black via-[#050912] to-black opacity-90" />

      <div className="absolute top-0 left-0 right-0 z-20 flex items-center justify-between px-6 md:px-12 py-4 bg-black/30 backdrop-blur border-b border-white/5">
        <div>
          <div className="text-[11px] uppercase tracking-[0.35em] text-emerald-200/80">AgroSmart 2.0</div>
          <div className="text-lg font-semibold text-white">Digital Twin Hologram</div>
        </div>
        <button
          onClick={() => navigate('/dashboard')}
          className="rounded-full bg-emerald-500 px-4 py-2 text-sm font-semibold text-emerald-950 shadow-[0_10px_30px_-12px_rgba(16,185,129,0.6)] transition hover:translate-y-[-1px] hover:bg-emerald-400 focus:outline-none focus:ring-2 focus:ring-emerald-300 focus:ring-offset-2 focus:ring-offset-black"
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
          <FarmScene data={data} normalized={normalized} irrigationOn={irrigationOn} tick={tick} />
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
          <p className="mt-2 max-w-2xl text-sm text-slate-300">AR-Enhanced Hybrid IoT Monitoring · Cinematic hologram of your live farm state. Read-only, monitoring-first.</p>
          <div className="mt-3 flex flex-wrap items-center gap-3 text-xs font-semibold">
            <div className="relative flex items-center gap-2">
              <span className="relative inline-flex h-3.5 w-3.5">
                <span key={tick} className="absolute inline-flex h-3.5 w-3.5 animate-ping rounded-full bg-emerald-400 opacity-70" />
                <span className="relative inline-flex h-3.5 w-3.5 rounded-full bg-emerald-300 shadow-[0_0_12px_rgba(52,211,153,0.9)]" />
              </span>
              <span className="text-emerald-100">LIVE</span>
            </div>
            <div className={`inline-flex items-center rounded-full border px-3 py-1 backdrop-blur ${statusTone}`}>
              <span className={`mr-2 h-2 w-2 rounded-full ${connected ? 'bg-emerald-300 shadow-[0_0_10px_#34d399]' : 'bg-amber-300'}`} />
              {connected ? 'Connected to Firebase' : 'Waiting for live data...'}
            </div>
            {!connected && (
              <span className="rounded-full bg-rose-500/10 px-3 py-1 text-rose-200 border border-rose-400/40">Disconnected</span>
            )}
            {error && (
              <span className="rounded-full bg-amber-500/10 px-3 py-1 text-amber-200 border border-amber-400/30">Listener issue</span>
            )}
          </div>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 18 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.9, ease: 'easeOut', delay: 0.1 }}
          className="px-6 pb-12 md:px-12"
        >
          <div className="grid grid-cols-2 gap-3 md:grid-cols-4">
            <MetricCard label="Temperature" value={formatValue(data.temperature, '°C')} stateLabel={states.temp} tone={toneForState(states.temp)} />
            <MetricCard label="Humidity" value={formatValue(data.humidity, '%')} tone="slate" />
            <MetricCard label="Soil Moisture" value={formatValue(data.soilMoisture, '')} stateLabel={states.soil} tone={toneForState(states.soil)} />
            <MetricCard label="Light" value={formatValue(data.lightLevel, '')} stateLabel={states.light} tone={toneForState(states.light)} />
          </div>

          <div className="mt-5 flex items-center justify-between gap-4 flex-col md:flex-row">
            <div className="w-full md:w-auto rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-sm text-slate-200 shadow-lg shadow-emerald-500/5 backdrop-blur flex items-center gap-2">
              Irrigation Status:
              <span className={`rounded-full border px-2 py-1 text-xs font-semibold ${toneForState(states.irrigation ? 'ON' : 'OFF')}`}>{irrigationLabel}</span>
            </div>
            <button
              onClick={() => navigate('/dashboard')}
              className="w-full md:w-auto rounded-full bg-emerald-500 px-6 py-3 text-center text-sm font-semibold text-emerald-950 shadow-[0_10px_40px_-12px_rgba(16,185,129,0.6)] transition hover:translate-y-[-1px] hover:bg-emerald-400 focus:outline-none focus:ring-2 focus:ring-emerald-300 focus:ring-offset-2 focus:ring-offset-black"
            >
              Enter Dashboard
            </button>
          </div>
        </motion.div>

        {params.get('debug') === '1' && (
          <div className="absolute bottom-4 right-4 z-20 w-full max-w-sm rounded-2xl border border-white/10 bg-black/70 p-4 text-xs text-slate-200 shadow-xl backdrop-blur">
            <div className="font-semibold text-emerald-200 mb-2">Calibration Debug</div>
            <div className="space-y-1">
              <DebugRow label="Raw Temp" value={`${formatValue(raw.temperature, '°C')}`} />
              <DebugRow label="Raw Soil" value={formatValue(raw.soilMoisture, '')} />
              <DebugRow label="Raw Light" value={formatValue(raw.lightLevel, '')} />
              <DebugRow label="Norm Soil" value={normalized.soil.toFixed(3)} />
              <DebugRow label="Norm Light" value={normalized.light.toFixed(3)} />
              <DebugRow label="State Soil" value={states.soil} />
              <DebugRow label="State Light" value={states.light} />
              <DebugRow label="State Temp" value={states.temp} />
              <DebugRow label="Irrigation" value={irrigationOn ? 'ON' : 'OFF'} />
            </div>
            <div className="mt-3 text-[11px] text-slate-400">Soil thr: dry&lt;{calibration.soil.dryMax}, optimal&lt;{calibration.soil.optimalMax}, wet&gt;{calibration.soil.wetMin} | Pump~{calibration.soil.pumpThreshold}</div>
          </div>
        )}
      </div>
    </div>
  )
}

function MetricCard({ label, value, stateLabel, tone = 'text-slate-200 border-slate-500/40 bg-slate-500/10' }) {
  return (
    <div className={`rounded-2xl border border-white/10 bg-white/5 px-4 py-3 shadow-lg shadow-sky-500/5 backdrop-blur`}>
      <div className="text-[11px] uppercase tracking-[0.2em] text-slate-400">{label}</div>
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

function DebugRow({ label, value }){
  return (
    <div className="flex justify-between gap-2"><span className="text-slate-400">{label}</span><span className="font-semibold text-white">{value}</span></div>
  )
}

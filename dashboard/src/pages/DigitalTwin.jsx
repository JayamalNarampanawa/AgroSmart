import React, { Suspense } from 'react'
import { Canvas } from '@react-three/fiber'
import { useNavigate } from 'react-router-dom'
import { motion } from 'framer-motion'
import FarmScene from '../three/FarmScene'
import useAgroSmartLiveData from '../three/useAgroSmartLiveData'

const formatValue = (v, suffix = '') => {
  if (v === undefined || v === null || Number.isNaN(Number(v))) return '--'
  const num = Number(v)
  return `${num.toFixed(1)}${suffix}`
}

export default function DigitalTwin() {
  const { data, connected } = useAgroSmartLiveData()
  const navigate = useNavigate()

  const statusTone = connected ? 'bg-emerald-500/30 border-emerald-400/50 text-emerald-100' : 'bg-amber-500/20 border-amber-400/40 text-amber-100'
  const irrigationLabel = data.irrigationStatus === true || data.irrigationStatus === 1 || String(data.irrigationStatus).toLowerCase() === 'on'
    ? 'ON'
    : 'OFF'

  return (
    <div className="relative min-h-screen w-screen overflow-hidden bg-black text-slate-100">
      <div className="absolute inset-0 pointer-events-none bg-gradient-to-b from-black via-[#050912] to-black opacity-90" />

      <Canvas
        className="fixed inset-0"
        shadows
        camera={{ position: [6, 3.6, 8], fov: 52 }}
        gl={{ antialias: true, powerPreference: 'high-performance' }}
      >
        <Suspense fallback={null}>
          <FarmScene data={data} />
        </Suspense>
      </Canvas>

      <div className="relative z-10 flex h-screen flex-col justify-between">
        <motion.div
          initial={{ opacity: 0, y: -12 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, ease: 'easeOut' }}
          className="px-6 pt-8 md:px-12"
        >
          <div className="text-xs uppercase tracking-[0.35em] text-emerald-200/80">AgroSmart 2.0</div>
          <h1 className="mt-3 text-3xl md:text-4xl font-semibold text-white">Digital Twin</h1>
          <p className="mt-2 max-w-2xl text-sm text-slate-300">AR-Enhanced Hybrid IoT Monitoring · Cinematic hologram of your live farm state. Read-only, monitoring-first.</p>
          <div className="mt-3 flex items-center gap-2 text-xs font-semibold">
            <span className="rounded-full bg-emerald-400/20 px-2 py-1 text-emerald-100">LIVE</span>
            <div className={`inline-flex items-center rounded-full border px-3 py-1 backdrop-blur ${statusTone}`}>
              <span className={`mr-2 h-2 w-2 rounded-full ${connected ? 'bg-emerald-300 shadow-[0_0_10px_#34d399]' : 'bg-amber-300'}`} />
              {connected ? 'Connected to Firebase' : 'Waiting for live data...'}
            </div>
          </div>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 18 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.9, ease: 'easeOut', delay: 0.1 }}
          className="px-6 pb-12 md:px-12"
        >
          <div className="grid grid-cols-2 gap-3 md:grid-cols-4">
            <MetricCard label="Temperature" value={formatValue(data.temperature, '°C')} />
            <MetricCard label="Humidity" value={formatValue(data.humidity, '%')} />
            <MetricCard label="Soil Moisture" value={formatValue(data.soilMoisture, '%')} />
            <MetricCard label="Light" value={formatValue(data.lightLevel, ' lux')} />
          </div>

          <div className="mt-5 flex items-center justify-between gap-4 flex-col md:flex-row">
            <div className={`w-full md:w-auto rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-sm text-slate-200 shadow-lg shadow-emerald-500/5 backdrop-blur`}>Irrigation Status: <span className="font-semibold text-white">{irrigationLabel}</span></div>
            <button
              onClick={() => navigate('/dashboard')}
              className="w-full md:w-auto rounded-full bg-emerald-500 px-6 py-3 text-center text-sm font-semibold text-emerald-950 shadow-[0_10px_40px_-12px_rgba(16,185,129,0.6)] transition hover:translate-y-[-1px] hover:bg-emerald-400 focus:outline-none focus:ring-2 focus:ring-emerald-300 focus:ring-offset-2 focus:ring-offset-black"
            >
              Enter Dashboard
            </button>
          </div>
        </motion.div>
      </div>
    </div>
  )
}

function MetricCard({ label, value }) {
  return (
    <div className="rounded-2xl border border-white/10 bg-white/5 px-4 py-3 shadow-lg shadow-sky-500/5 backdrop-blur">
      <div className="text-[11px] uppercase tracking-[0.2em] text-slate-400">{label}</div>
      <div className="mt-1 text-xl font-semibold text-white">{value}</div>
    </div>
  )
}

import React from 'react'
import { motion } from 'framer-motion'
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, AreaChart, Area, BarChart, Bar, Legend, ReferenceLine } from 'recharts'
import useMotionPreferences from '../hooks/useMotionPreferences.jsx'
import useSoilMoistureSettings from '../hooks/useSoilMoistureSettings'
import { soilWetnessPercent } from '../utils/soilMoisture'
import useReplay from '../replay/useReplay'

function timeLabel(ts){
  if(!ts) return ''
  const d = new Date(Number(ts))
  const today = new Date()
  if(d.toDateString() === today.toDateString()) return d.toLocaleTimeString()
  return d.toLocaleDateString()
}

const shortTime = (ts) => ts ? new Date(Number(ts)).toLocaleTimeString([], { hour12: false }) : ''

function groupPumpByDay(records){
  const map = {}
  records.forEach(r=>{
    if(!r || r.source !== 'sensor') return
    const ts = r.timestamp || Date.now()
    const d = new Date(Number(ts))
    const key = d.getFullYear() + '-' + String(d.getMonth()+1).padStart(2,'0') + '-' + String(d.getDate()).padStart(2,'0')
    if(!map[key]) map[key] = {time:key, count:0}
    if(r.pumpStatus === true || r.pumpStatus === 1) map[key].count += 1
  })
  return Object.values(map).sort((a,b)=> new Date(a.time) - new Date(b.time)).map(x=>({time:x.time, pumpOnCount: x.count}))
}

export default function ChartsPanel({ timeseries = [] }){
  const { enabled, reducedMotion } = useMotionPreferences()
  const allowMotion = enabled && !reducedMotion
  const soilConfig = useSoilMoistureSettings()
  const { mode, replayIndex, buffer } = useReplay()

  const activeTs = mode === 'REPLAY' ? buffer[replayIndex]?.ts : null
  const activeLabel = activeTs ? timeLabel(activeTs) : null

  const data = timeseries.map(h=>({
    original: h,
    ts: h.timestamp,
    time: timeLabel(h.timestamp),
    tempHistorical: h.source === 'historical' ? h.temperature : null,
    tempSensor: h.source === 'sensor' ? h.temperature : null,
    soilMoisture: h.source === 'sensor' ? h.soilMoisture : null,
    soilMoistureWetness: h.source === 'sensor'
      ? soilWetnessPercent(h.soilMoisture, soilConfig.wetMin, soilConfig.dryMax)
      : null,
    pumpStatus: h.source === 'sensor' ? (h.pumpStatus ? 1 : 0) : null
  }))

  const pumpSeries = groupPumpByDay(timeseries)

  const enter = allowMotion
    ? { initial: { opacity: 0, y: 16 }, animate: { opacity: 1, y: 0 }, transition: { duration: 0.5, ease: 'easeOut' } }
    : {}

  return (
    <div className="space-y-6">
      <div className="mb-2 flex items-center justify-between">
        <div>
          <div className="text-xs uppercase tracking-[0.2em] text-slate-400">Analytics</div>
          <div className="text-xl font-semibold">Climate Signals</div>
        </div>
        <div className="text-xs text-slate-400">Showing {data.length} points â€¢ Past = simulated historical baseline</div>
      </div>

      <motion.div className="chart-3d rounded-xl border border-white/8 bg-slate-950/40 p-4" {...enter}>
        <div className="flex items-center justify-between mb-3">
          <h3 className="text-base font-semibold">Temperature (°C)</h3>
          <div className="text-xs text-slate-400 flex items-center gap-2">
            <span className="px-2 py-1 rounded-full bg-white/6">Historical</span>
            <span className="px-2 py-1 rounded-full bg-white/6">Real-time</span>
            {activeTs && <span className="px-2 py-1 rounded-full bg-cyan-500/15 text-cyan-100">Replay @ {shortTime(activeTs)}</span>}
          </div>
        </div>
        <div style={{height:260}}>
          <ResponsiveContainer>
            <LineChart data={data}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="time" />
              <YAxis />
              <Tooltip />
              <Legend />
              <Line name="Historical (Kaggle)" type="monotone" dataKey="tempHistorical" stroke="#38bdf8" strokeWidth={1.5} dot={false} isAnimationActive={allowMotion} />
              <Line name="Sensors" type="monotone" dataKey="tempSensor" stroke="#fb7185" strokeWidth={2.5} dot={<LiveDot />} isAnimationActive={allowMotion} />
              {activeLabel && (
                <ReferenceLine
                  x={activeLabel}
                  stroke="#22d3ee"
                  strokeDasharray="4 2"
                  label={{ value: `Replay @ ${shortTime(activeTs)}`, position: 'top', fill: '#22d3ee', fontSize: 11 }}
                  ifOverflow="extendDomain"
                />
              )}
            </LineChart>
          </ResponsiveContainer>
        </div>
      </motion.div>

      <motion.div className="chart-3d rounded-xl border border-white/8 bg-slate-950/40 p-4" {...enter}>
        <div className="flex items-center justify-between mb-2">
          <h3 className="text-base font-semibold">Soil Moisture</h3>
          <div className="text-xs text-slate-400">Wetness (inverted sensor output)</div>
        </div>
        <div style={{height:220}}>
          <ResponsiveContainer>
            <AreaChart data={data}>
              <defs>
                <linearGradient id="soilGrad" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#10b981" stopOpacity={0.8}/>
                  <stop offset="95%" stopColor="#10b981" stopOpacity={0.1}/>
                </linearGradient>
              </defs>
              <XAxis dataKey="time" />
              <YAxis domain={[0, 100]} />
              <Tooltip content={<SoilMoistureTooltip />} />
              <Area name="Wetness (%)" type="monotone" dataKey="soilMoistureWetness" stroke="#34d399" fillOpacity={1} fill="url(#soilGrad)" isAnimationActive={allowMotion} />
              {activeLabel && (
                <ReferenceLine
                  x={activeLabel}
                  stroke="#22d3ee"
                  strokeDasharray="4 2"
                  label={{ value: `Replay @ ${shortTime(activeTs)}`, position: 'top', fill: '#22d3ee', fontSize: 11 }}
                  ifOverflow="extendDomain"
                />
              )}
            </AreaChart>
          </ResponsiveContainer>
        </div>
      </motion.div>

      <motion.div className="chart-3d rounded-xl border border-white/8 bg-slate-950/40 p-4" {...enter}>
        <div className="flex items-center justify-between mb-2">
          <h3 className="text-base font-semibold">Irrigation Activity</h3>
          <div className="text-xs text-slate-400">Pump ON count per day</div>
        </div>
        <div style={{height:180}}>
          <ResponsiveContainer>
            <BarChart data={pumpSeries}>
              <XAxis dataKey="time" />
              <YAxis />
              <Tooltip />
              <Bar dataKey="pumpOnCount" fill="#38bdf8" isAnimationActive={allowMotion} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </motion.div>
    </div>
  )
}

function LiveDot(props){
  const { cx, cy, stroke } = props
  if(cx == null || cy == null) return null
  return (
    <circle cx={cx} cy={cy} r={3.4} fill={stroke} className="live-dot" />
  )
}

function SoilMoistureTooltip({ active, payload, label }){
  if(!active || !payload || payload.length === 0) return null
  const row = payload[0]?.payload || {}
  const wetness = row.soilMoistureWetness
  const raw = row.soilMoisture
  return (
    <div className="rounded-lg border border-white/10 bg-slate-950/90 px-3 py-2 text-xs text-slate-100">
      <div className="text-slate-300">{label}</div>
      <div className="mt-1">Wetness: <span className="font-semibold">{wetness == null ? '--' : `${wetness}%`}</span></div>
      <div>Raw: <span className="font-semibold">{raw == null ? '--' : raw}</span></div>
    </div>
  )
}

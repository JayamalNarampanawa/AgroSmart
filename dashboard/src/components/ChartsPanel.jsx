import React from 'react'
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, AreaChart, Area, BarChart, Bar, Legend } from 'recharts'

function timeLabel(ts){
  if(!ts) return ''
  const d = new Date(Number(ts))
  const today = new Date()
  if(d.toDateString() === today.toDateString()) return d.toLocaleTimeString()
  return d.toLocaleDateString()
}

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
  const data = timeseries.map(h=>({
    original: h,
    time: timeLabel(h.timestamp),
    tempHistorical: h.source === 'historical' ? h.temperature : null,
    tempSensor: h.source === 'sensor' ? h.temperature : null,
    soilMoisture: h.source === 'sensor' ? h.soilMoisture : null,
    pumpStatus: h.source === 'sensor' ? (h.pumpStatus ? 1 : 0) : null
  }))

  const pumpSeries = groupPumpByDay(timeseries)

  return (
    <div className="space-y-6">
      <div className="mb-2 flex items-center justify-between">
        <div>
          <div className="text-xs uppercase tracking-[0.2em] text-slate-400">Analytics</div>
          <div className="text-xl font-semibold">Climate Signals</div>
        </div>
        <div className="text-xs text-slate-400">Showing {data.length} points • Past = simulated historical baseline</div>
      </div>

      <div className="rounded-xl border border-white/8 bg-slate-950/40 p-4">
        <div className="flex items-center justify-between mb-3">
          <h3 className="text-base font-semibold">Temperature (°C)</h3>
          <div className="text-xs text-slate-400 flex items-center gap-2">
            <span className="px-2 py-1 rounded-full bg-white/6">Historical</span>
            <span className="px-2 py-1 rounded-full bg-white/6">Real-time</span>
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
              <Line name="Historical (Kaggle)" type="monotone" dataKey="tempHistorical" stroke="#06b6d4" dot={false} />
              <Line name="Sensors" type="monotone" dataKey="tempSensor" stroke="#ef4444" dot={false} />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </div>

      <div className="rounded-xl border border-white/8 bg-slate-950/40 p-4">
        <div className="flex items-center justify-between mb-2">
          <h3 className="text-base font-semibold">Soil Moisture</h3>
          <div className="text-xs text-slate-400">Sensor-only values</div>
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
              <YAxis />
              <Tooltip />
              <Area type="monotone" dataKey="soilMoisture" stroke="#10b981" fillOpacity={1} fill="url(#soilGrad)" />
            </AreaChart>
          </ResponsiveContainer>
        </div>
      </div>

      <div className="rounded-xl border border-white/8 bg-slate-950/40 p-4">
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
              <Bar dataKey="pumpOnCount" fill="#0ea5e9" />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  )
}

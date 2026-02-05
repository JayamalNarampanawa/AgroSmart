import React from 'react'
import { ResponsiveContainer, AreaChart, Area, XAxis, YAxis, Tooltip, Legend } from 'recharts'

function formatTime(ts){
  const d = new Date(Number(ts))
  if(Number.isNaN(d.getTime())) return ''
  return d.toLocaleString([], { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' })
}

function RainTooltip({ active, payload, label }){
  if(!active || !payload || payload.length === 0) return null
  const row = payload[0]?.payload || {}
  const observed = row.rainfall ?? null
  const forecast = row.rainfallForecast ?? null
  return (
    <div className="rounded-lg border border-white/10 bg-slate-950/90 px-3 py-2 text-xs text-slate-100">
      <div className="text-slate-300">{label}</div>
      {observed !== null && <div className="mt-1">Observed: <span className="font-semibold">{observed} mm</span></div>}
      {forecast !== null && <div className="mt-1">Forecast: <span className="font-semibold">{forecast} mm</span></div>}
    </div>
  )
}

export default function WeatherTrendChart({ history = [], forecast = [] }){
  const hist = history.map(h=>({
    ts: h.ts,
    time: formatTime(h.ts),
    rainfall: typeof h.rainfall === 'number' ? Number(h.rainfall.toFixed(2)) : 0,
    type: 'history'
  }))
  const fore = forecast.map(f=>({
    ts: f.ts,
    time: formatTime(f.ts),
    rainfallForecast: typeof f.rainfall === 'number' ? Number(f.rainfall.toFixed(2)) : 0,
    type: 'forecast'
  }))

  const data = [...hist, ...fore].sort((a,b)=>a.ts - b.ts)

  if(data.length === 0){
    return <div className="text-xs text-slate-400">No rainfall history yet.</div>
  }

  return (
    <div style={{height:160}}>
      <ResponsiveContainer>
        <AreaChart data={data}>
          <defs>
            <linearGradient id="rainGrad" x1="0" y1="0" x2="0" y2="1">
              <stop offset="5%" stopColor="#38bdf8" stopOpacity={0.7}/>
              <stop offset="95%" stopColor="#38bdf8" stopOpacity={0.08}/>
            </linearGradient>
            <linearGradient id="rainForecastGrad" x1="0" y1="0" x2="0" y2="1">
              <stop offset="5%" stopColor="#f59e0b" stopOpacity={0.6}/>
              <stop offset="95%" stopColor="#f59e0b" stopOpacity={0.06}/>
            </linearGradient>
          </defs>
          <XAxis dataKey="time" />
          <YAxis />
          <Tooltip content={<RainTooltip />} />
          <Legend />
          <Area name="Observed Rain" type="monotone" dataKey="rainfall" stroke="#38bdf8" fillOpacity={1} fill="url(#rainGrad)" />
          <Area name="Forecast Rain" type="monotone" dataKey="rainfallForecast" stroke="#f59e0b" strokeDasharray="4 4" fillOpacity={0.9} fill="url(#rainForecastGrad)" />
        </AreaChart>
      </ResponsiveContainer>
    </div>
  )
}

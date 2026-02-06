import React from 'react'
import WeatherTrendChart from './WeatherTrendChart'
import WeatherForecastPanel from './WeatherForecastPanel'
import { soilWetnessPercent } from '../utils/soilMoisture'
import useSoilMoistureSettings from '../hooks/useSoilMoistureSettings'

function formatUpdatedAt(ts){
  if(!ts) return 'Unknown'
  const d = new Date(Number(ts))
  if(Number.isNaN(d.getTime())) return 'Unknown'
  return d.toLocaleString()
}

function rainLabel(rainfall){
  if(rainfall > 2) return 'Rain detected'
  if(rainfall > 0) return 'Light rain detected'
  return 'No rain detected'
}

function computeRainTrend(history){
  if(!history || history.length < 4) return 'steady'
  const last = history.slice(-3).reduce((a,b)=>a + (b.rainfall || 0), 0) / 3
  const prev = history.slice(-6, -3).reduce((a,b)=>a + (b.rainfall || 0), 0) / 3
  if(last - prev > 0.2) return 'rising'
  if(prev - last > 0.2) return 'falling'
  return 'steady'
}

export default function WeatherPanel({ weather, history, forecast, current }){
  const soilConfig = useSoilMoistureSettings()
  const rainfall = typeof weather?.rainfall === 'number' ? weather.rainfall : 0
  const windSpeed = typeof weather?.windSpeed === 'number' ? weather.windSpeed : null
  const updatedAt = weather?.updatedAt?.seconds ? weather.updatedAt.seconds * 1000 : weather?.updatedAt
  const trend = computeRainTrend(history)
  const soilWetness = soilWetnessPercent(current?.soilMoisture, soilConfig.wetMin, soilConfig.dryMax)

  let actionHint = 'Weather looks stable; keep monitoring.'
  if(trend === 'rising'){
    actionHint = 'Consider delaying irrigation; rain is increasing.'
  }else if(rainfall === 0 && soilWetness !== null && soilWetness < 30){
    actionHint = 'Irrigation recommended; no rain and soil is dry.'
  }

  return (
    <div className="holo-panel rounded-2xl border border-white/8 bg-gradient-to-br from-slate-950/70 via-slate-950/40 to-slate-900/50 p-6">
      <div className="flex items-center justify-between mb-4">
        <div>
          <div className="text-xs uppercase tracking-[0.2em] text-slate-400">Weather</div>
          <div className="text-lg font-semibold">Local Conditions</div>
        </div>
        <div className="text-xs text-slate-400">Updated: {formatUpdatedAt(updatedAt)}</div>
      </div>

      <div className="grid grid-cols-2 md:grid-cols-3 gap-3 text-sm">
        <div className="rounded-xl border border-white/8 bg-white/3 p-3">
          <div className="text-xs uppercase tracking-widest text-slate-400">Rainfall</div>
          <div className="mt-1 font-semibold">{rainfall} mm</div>
        </div>
        <div className="rounded-xl border border-white/8 bg-white/3 p-3">
          <div className="text-xs uppercase tracking-widest text-slate-400">Wind</div>
          <div className="mt-1 font-semibold">{windSpeed == null ? '--' : `${windSpeed} m/s`}</div>
        </div>
        <div className="rounded-xl border border-white/8 bg-white/3 p-3">
          <div className="text-xs uppercase tracking-widest text-slate-400">Condition</div>
          <div className="mt-1 font-semibold">{rainLabel(rainfall)}</div>
        </div>
      </div>

      <div className="mt-3 text-xs text-slate-400">{rainLabel(rainfall)}</div>

      <div className="mt-5">
        <div className="text-sm font-semibold mb-2">Rainfall trend and forecast</div>
        <WeatherTrendChart history={history} forecast={forecast} />
      </div>

      <div className="mt-5">
        <div className="text-sm font-semibold mb-2">Forecast outlook</div>
        <WeatherForecastPanel forecast={forecast} />
      </div>

      <div className="mt-4 text-sm text-slate-300">
        <span className="font-semibold">Action hint:</span> {actionHint}
      </div>
    </div>
  )
}

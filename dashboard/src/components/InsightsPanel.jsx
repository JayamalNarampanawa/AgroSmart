import React from 'react'
import useSoilMoistureSettings from '../hooks/useSoilMoistureSettings'
import { soilWetnessPercent } from '../utils/soilMoisture'

export default function InsightsPanel({ current }){
  const soilConfig = useSoilMoistureSettings()
  const soil = current?.soilMoisture ?? null
  const wetness = soilWetnessPercent(soil, soilConfig.wetMin, soilConfig.dryMax)
  let soilStatus = 'Unknown'
  let irrigationSuggestion = 'N/A'

  if (wetness !== null){
    if (wetness < 30) { soilStatus = 'Dry'; irrigationSuggestion = 'Irrigation Recommended' }
    else if (wetness < 70) { soilStatus = 'Optimal'; irrigationSuggestion = 'No action' }
    else { soilStatus = 'Wet'; irrigationSuggestion = 'No irrigation' }
  }

  const envTrend = current ? `T:${current.temperature}°C · H:${current.humidity}%` : 'No data'

  return (
    <div>
      <div className="flex items-center justify-between mb-4">
        <div>
          <div className="text-xs uppercase tracking-[0.2em] text-slate-400">Insights</div>
          <h3 className="text-lg font-semibold">Smart Insights</h3>
        </div>
        <div className="text-xs text-slate-400">Auto-evaluated</div>
      </div>
      <div className="grid gap-3">
        <div className="p-4 rounded-xl bg-white/4 border border-white/8">
          <div className="text-xs uppercase tracking-widest text-slate-400">Soil Condition</div>
          <div className="text-lg font-semibold mt-1">{soilStatus}</div>
        </div>
        <div className="p-4 rounded-xl bg-white/4 border border-white/8">
          <div className="text-xs uppercase tracking-widest text-slate-400">Suggestion</div>
          <div className="text-lg font-semibold mt-1">{irrigationSuggestion}</div>
        </div>
        <div className="p-4 rounded-xl bg-white/3 border border-white/6">
          <div className="text-xs uppercase tracking-widest text-slate-400">Environment</div>
          <div className="text-sm mt-1">{envTrend}</div>
        </div>
      </div>
    </div>
  )
}

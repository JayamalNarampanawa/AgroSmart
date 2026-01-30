import React from 'react'

export default function InsightsPanel({ current }){
  const soil = current?.soilMoisture ?? null
  let soilStatus = 'Unknown'
  let irrigationSuggestion = 'N/A'

  if (soil !== null){
    if (soil > 2200) { soilStatus = 'Dry'; irrigationSuggestion = 'Irrigation Recommended' }
    else if (soil > 1200) { soilStatus = 'Optimal'; irrigationSuggestion = 'No action' }
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

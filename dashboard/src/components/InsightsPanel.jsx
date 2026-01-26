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
      <h3 className="text-lg font-semibold mb-2">Smart Insights</h3>
      <div className="space-y-3">
        <div className="p-3 rounded-md bg-black/20 border border-white/4">
          <div className="text-sm text-slate-400">Soil Condition</div>
          <div className="text-lg font-semibold">{soilStatus}</div>
        </div>
        <div className="p-3 rounded-md bg-black/20 border border-white/4">
          <div className="text-sm text-slate-400">Suggestion</div>
          <div className="text-lg font-semibold">{irrigationSuggestion}</div>
        </div>
        <div className="p-3 rounded-md bg-black/10 border border-white/3">
          <div className="text-sm text-slate-400">Environmental Summary</div>
          <div className="text-sm">{envTrend}</div>
        </div>
      </div>
    </div>
  )
}

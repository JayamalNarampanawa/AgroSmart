import React from 'react'

export default function AlertsPanel({ current }){
  const alerts = []
  if (!current) return <div className="text-slate-400">No realtime data</div>

  if (current.temperature > 35) alerts.push({level:'high', text:'Temperature too high'})
  if (current.soilMoisture > 2200) alerts.push({level:'medium', text:'Soil is very dry'})
  if (current.lightLevel < 100) alerts.push({level:'low', text:'Light level low'})

  return (
    <div>
      <h3 className="text-lg font-semibold mb-3">Alerts</h3>
      {alerts.length === 0 ? (
        <div className="p-3 rounded-md bg-emerald-800/10 border border-emerald-700/20 text-emerald-300">All readings normal</div>
      ) : (
        <div className="space-y-2">
          {alerts.map((a,i)=> (
            <div key={i} className={`p-3 rounded-md card-hover ${a.level==='high' ? 'bg-red-700/20 border border-red-600' : a.level==='medium' ? 'bg-yellow-700/12 border border-yellow-600' : 'bg-white/3 border border-white/6'}`}>
              <div className="flex items-center justify-between">
                <div className="text-sm font-semibold">{a.text}</div>
                <div className={`px-2 py-1 rounded text-xs ${a.level==='high' ? 'badge-on' : 'badge-off'}`}>{a.level.toUpperCase()}</div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

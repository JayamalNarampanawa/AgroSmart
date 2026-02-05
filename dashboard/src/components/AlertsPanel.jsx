import React from 'react'
import useSoilMoistureSettings from '../hooks/useSoilMoistureSettings'
import { soilWetnessPercent } from '../utils/soilMoisture'

export default function AlertsPanel({ current }){
  const soilConfig = useSoilMoistureSettings()
  const alerts = []
  if (!current) return <div className="text-slate-400">No realtime data</div>

  const wetness = soilWetnessPercent(current.soilMoisture, soilConfig.wetMin, soilConfig.dryMax)
  if (current.temperature > 35) alerts.push({level:'high', text:'Temperature too high'})
  if (wetness !== null && wetness < 30) alerts.push({level:'medium', text:'Soil is very dry'})
  if (current.lightLevel < 100) alerts.push({level:'low', text:'Light level low'})

  return (
    <div>
      <div className="flex items-center justify-between mb-4">
        <div>
          <div className="text-xs uppercase tracking-[0.2em] text-slate-400">Notifications</div>
          <h3 className="text-lg font-semibold">Alerts</h3>
        </div>
        <div className="text-xs text-slate-400">{alerts.length} active</div>
      </div>
      {alerts.length === 0 ? (
        <div className="p-4 rounded-xl bg-emerald-500/10 border border-emerald-400/20 text-emerald-200">
          All readings normal
        </div>
      ) : (
        <div className="space-y-3">
          {alerts.map((a,i)=> (
            <div key={i} className={`p-4 rounded-xl border ${a.level==='high' ? 'bg-red-500/10 border-red-400/30' : a.level==='medium' ? 'bg-amber-500/10 border-amber-400/30' : 'bg-white/4 border-white/8'}`}>
              <div className="flex items-center justify-between gap-3">
                <div className="text-sm font-semibold">{a.text}</div>
                <div className={`px-2.5 py-1 rounded-full text-[11px] font-semibold uppercase tracking-wide ${a.level==='high' ? 'bg-red-500 text-white' : a.level==='medium' ? 'bg-amber-500 text-white' : 'bg-white/10 text-slate-200'}`}>
                  {a.level.toUpperCase()}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

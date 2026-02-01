import React from 'react'

export default function FeatureDiffPanel({ diffs = {}, crop }){
  if(!diffs || Object.keys(diffs).length === 0) return null

  return (
    <div className="holo-panel">
      <div className="text-xs uppercase tracking-[0.2em] text-slate-400">Comparison</div>
      <div className="font-semibold mb-3">Compared to Kaggle historical mean for <span className="capitalize">{crop}</span></div>
      <div className="grid gap-2 text-sm text-slate-200">
        {Object.entries(diffs).map(([k,v])=> (
          <div key={k} className="flex items-center justify-between rounded-lg border border-white/8 bg-white/3 px-3 py-2">
            <div className="capitalize">{k}</div>
            <div className="text-slate-100">{v === null ? 'N/A' : `${v}`}</div>
          </div>
        ))}
      </div>
    </div>
  )
}

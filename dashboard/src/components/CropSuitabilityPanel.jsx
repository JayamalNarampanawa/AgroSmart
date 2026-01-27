import React from 'react'

function Progress({value}){
  return (
    <div className="w-full bg-slate-100 dark:bg-slate-700 rounded h-3 overflow-hidden">
      <div style={{width: `${value}%`}} className="h-3 bg-gradient-to-r from-emerald-400 to-green-600" />
    </div>
  )
}

export default function CropSuitabilityPanel({ suitability }){
  if(!suitability) return (
    <div className="p-4 rounded-lg shadow-md bg-white dark:bg-slate-800">Waiting for AI suitability results…</div>
  )

  // suitability may be either totals object or the full breakdown structure
  const breakdown = suitability?.breakdown ?? null
  const totals = suitability?.totals ?? (suitability || null)

  const cropKeys = ['kidneybeans','mungbean','chickpea']
  const entries = cropKeys.map(k=>({ key:k, score: totals?.[k] ?? 0, detail: breakdown?.[k] ?? null }))
  entries.sort((a,b)=>b.score - a.score)
  const top = entries[0]

  return (
    <div className="p-4 rounded-lg shadow-md bg-gradient-to-r from-white to-slate-50 dark:from-slate-800 dark:to-slate-900">
      <div className="flex items-center justify-between">
        <div className="font-semibold">Crop Suitability</div>
        <div className="text-xs text-slate-500">Rule-based v1</div>
      </div>
      <div className="mt-3 space-y-3">
        {entries.map(e=> (
          <div key={e.key} className={`p-3 rounded ${top.key===e.key ? 'ring-2 ring-emerald-300 bg-emerald-50 dark:bg-emerald-900/20' : 'bg-transparent'}`}>
            <div className="flex items-center justify-between mb-2">
              <div className="text-sm font-medium capitalize">{e.key}</div>
              <div className="text-sm font-semibold">{e.score ?? 0}%</div>
            </div>
            <Progress value={e.score ?? 0} />
            {e.detail?.why && (
              <div className="mt-2 text-xs text-slate-500">
                <strong>Why:</strong> {e.detail.why.join(' • ')}
              </div>
            )}
          </div>
        ))}
      </div>
      <div className="mt-3 text-xs text-slate-500">Scores are computed from historical patterns vs live sensor data (rule-based v1).</div>
    </div>
  )
}

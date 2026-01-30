import React from 'react'

function Progress({value}){
  return (
    <div className="w-full bg-slate-900/60 border border-white/8 rounded-full h-2 overflow-hidden">
      <div style={{width: `${value}%`}} className="h-2 bg-gradient-to-r from-emerald-400 to-green-600" />
    </div>
  )
}

export default function CropSuitabilityPanel({ suitability }){
  if(!suitability) return (
    <div className="p-4 rounded-xl border border-white/8 bg-slate-950/40">Waiting for AI suitability results...</div>
  )

  const breakdown = suitability?.breakdown ?? null
  const totals = suitability?.totals ?? (suitability || null)

  const cropKeys = ['kidneybeans','mungbean','chickpea']
  const entries = cropKeys.map(k=>({ key:k, score: totals?.[k] ?? 0, detail: breakdown?.[k] ?? null }))
  entries.sort((a,b)=>b.score - a.score)
  const top = entries[0]

  return (
    <div className="rounded-2xl border border-white/8 bg-gradient-to-br from-slate-950/70 via-slate-950/40 to-slate-900/50 p-6">
      <div className="flex items-center justify-between">
        <div>
          <div className="text-xs uppercase tracking-[0.2em] text-slate-400">Suitability</div>
          <div className="text-lg font-semibold">Crop Suitability</div>
        </div>
        <div className="text-xs text-slate-400">Rule-based v1</div>
      </div>
      <div className="mt-5 space-y-3">
        {entries.map(e=> (
          <div key={e.key} className={`p-4 rounded-xl border ${top.key===e.key ? 'border-emerald-400/40 bg-emerald-500/10' : 'border-white/8 bg-white/3'}`}>
            <div className="flex items-center justify-between mb-2">
              <div className="text-sm font-medium capitalize">{e.key}</div>
              <div className="text-sm font-semibold">{e.score ?? 0}%</div>
            </div>
            <Progress value={e.score ?? 0} />
            {e.detail?.why && (
              <div className="mt-2 text-xs text-slate-400">
                <strong>Why:</strong> {e.detail.why.join(' • ')}
              </div>
            )}
          </div>
        ))}
      </div>
      <div className="mt-4 text-xs text-slate-400">Scores are computed from historical patterns vs live sensor data (rule-based v1).</div>
    </div>
  )
}

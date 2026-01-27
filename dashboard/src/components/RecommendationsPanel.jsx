import React from 'react'

export default function RecommendationsPanel({ recs }){
  if(!recs) return (
    <div className="p-4 rounded-lg shadow-md bg-white dark:bg-slate-800">Waiting for recommendations…</div>
  )

  const confidence = recs.confidence ?? 0
  const confColor = confidence > 75 ? 'bg-green-600' : (confidence > 40 ? 'bg-amber-500' : 'bg-red-500')

  return (
    <div className="p-4 rounded-lg shadow-md bg-gradient-to-r from-white to-slate-50 dark:from-slate-800 dark:to-slate-900">
      <div className="flex items-center justify-between">
        <div className="font-semibold">Recommendations</div>
        <div className="text-sm px-2 py-1 rounded-full text-white {confColor}">{recs.topCrop}</div>
      </div>
      <div className="mt-3">
        <div className="mb-2 text-sm text-slate-700 dark:text-slate-300">Top crop: <span className="font-semibold capitalize">{recs.topCrop}</span></div>
        <ul className="list-disc list-inside text-sm space-y-1 text-slate-700 dark:text-slate-300">
          {Array.isArray(recs.actions) && recs.actions.map((a,i)=>(<li key={i}>{a}</li>))}
        </ul>
        <div className="mt-3 flex items-center justify-between">
          <div className="text-xs text-slate-500">Confidence</div>
          <div className="w-24 h-3 rounded overflow-hidden bg-slate-100 dark:bg-slate-700">
            <div style={{width: `${confidence}%`}} className={`h-3 ${confColor}`} />
          </div>
        </div>
      </div>
    </div>
  )
}

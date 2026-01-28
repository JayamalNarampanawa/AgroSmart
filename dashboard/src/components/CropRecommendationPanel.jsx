import React from 'react'
import useRecommendationData from '../hooks/useRecommendationData'

export default function CropRecommendationPanel(){
  const rec = useRecommendationData()
  if(!rec) return (
    <div className="p-4 rounded-lg shadow-md bg-white dark:bg-slate-800">No recommendation yet</div>
  )

  const best = rec.recommendedCrop
  const top3 = Array.isArray(rec.top3) ? rec.top3 : Object.entries(rec.scores||{}).map(([c,s])=>({crop:c,score:s})).sort((a,b)=>a.score-b.score).slice(0,3)

  return (
    <div className="p-4 rounded-lg shadow-md bg-gradient-to-r from-white to-slate-50 dark:from-slate-800 dark:to-slate-900">
      <div className="flex items-center justify-between">
        <div className="font-semibold">Crop Recommendation</div>
        <div className="text-sm px-2 py-1 rounded-full bg-indigo-600 text-white capitalize">{best}</div>
      </div>
      <div className="mt-3">
        <div className="text-sm text-slate-700 dark:text-slate-300">Top 3</div>
        <ul className="mt-2 list-decimal list-inside text-sm">
          {top3.map((t,i)=>(
            <li key={i} className="capitalize">{t.crop} — score: {t.score === null ? 'N/A' : String(Math.round(t.score * 100)/100)}</li>
          ))}
        </ul>
        <div className="mt-3 text-sm text-slate-600 dark:text-slate-300">
          <div className="font-semibold">Inputs used</div>
          <pre className="text-xs bg-slate-100 dark:bg-slate-800 p-2 rounded mt-1">{JSON.stringify(rec.inputUsed, null, 2)}</pre>
        </div>
      </div>
    </div>
  )
}

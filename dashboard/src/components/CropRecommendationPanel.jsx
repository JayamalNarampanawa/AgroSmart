import React, { useEffect, useState } from 'react'
import useRecommendationData from '../hooks/useRecommendationData'
import { getMlPrediction } from '../services/mlService'

export default function CropRecommendationPanel(){
  const rec = useRecommendationData()
  const [mlResult, setMlResult] = useState(null)
  const [mlError, setMlError] = useState(null)

  const best = rec?.recommendedCrop
  const top3 = Array.isArray(rec?.top3)
    ? rec.top3
    : Object.entries(rec?.scores||{}).map(([c,s])=>({crop:c,score:s})).sort((a,b)=>a.score-b.score).slice(0,3)
  const matchLevel = rec?.matchLevel || "Unknown"
  const reasons = Array.isArray(rec?.reasons) ? rec.reasons : []
  const badgeText = matchLevel === "Unknown" ? "Unknown" : `${matchLevel} Match`
  const badgeClass = matchLevel === "Good"
    ? "bg-emerald-600 text-white"
    : matchLevel === "Moderate"
      ? "bg-yellow-500 text-white"
      : matchLevel === "Poor"
        ? "bg-red-600 text-white"
        : "bg-slate-500 text-white"

  useEffect(()=>{
    let alive = true
    const input = rec?.inputUsed
    if(!input || !best) return
    const payload = {
      N: input.N,
      P: input.P,
      K: input.K,
      temperature: input.temperature,
      humidity: input.humidity,
      rainfall: input.rainfall,
      ph: input.ph
    }

    getMlPrediction(payload).then(out=>{
      if(!alive) return
      setMlResult(out)
      setMlError(null)
    }).catch(err=>{
      if(!alive) return
      setMlResult(null)
      setMlError(err)
      console.error('ML prediction failed', err)
    })

    return ()=>{ alive = false }
  }, [best, rec?.inputUsed])

  const mlReady = !!(mlResult?.predictedCrop && typeof mlResult?.confidence === 'number')
  const mlValidated = mlReady && mlResult.predictedCrop === best && mlResult.confidence >= 0.6
  const mlBadgeClass = mlValidated ? "bg-emerald-600 text-white" : "bg-amber-500 text-white"
  const mlBadgeText = mlValidated ? "Validated by ML" : "ML result differs – review recommended"
  const confidencePct = mlReady ? (mlResult.confidence * 100).toFixed(2) : null

  if(!rec) return (
    <div className="p-4 rounded-lg shadow-md bg-white dark:bg-slate-800">No recommendation yet</div>
  )

  return (
    <div className="p-4 rounded-lg shadow-md bg-gradient-to-r from-white to-slate-50 dark:from-slate-800 dark:to-slate-900">
      <div className="flex items-center justify-between">
        <div className="font-semibold">Crop Recommendation</div>
        <div className="flex items-center gap-2">
          <div className={`text-xs px-2 py-1 rounded-full font-semibold uppercase tracking-wide ${badgeClass}`}>{badgeText}</div>
          <div className="text-sm px-2 py-1 rounded-full bg-indigo-600 text-white capitalize">{best}</div>
        </div>
      </div>
      <div className="mt-3">
        <div className="text-sm text-slate-700 dark:text-slate-300">Why this crop?</div>
        {reasons.length === 0 ? (
          <div className="mt-2 text-sm text-slate-500 dark:text-slate-400">No explanation available.</div>
        ) : (
          <ul className="mt-2 list-disc list-inside text-sm text-slate-700 dark:text-slate-300">
            {reasons.map((r,i)=>(
              <li key={i}>{r}</li>
            ))}
          </ul>
        )}
        <div className="text-sm text-slate-700 dark:text-slate-300">Top 3</div>
        <ul className="mt-2 list-decimal list-inside text-sm">
          {top3.map((t,i)=>(
            <li key={i} className="capitalize">{t.crop} - score: {t.score === null ? 'N/A' : String(Math.round(t.score * 100)/100)}</li>
          ))}
        </ul>
        <div className="mt-4">
          <div className="flex items-center justify-between">
            <div className="font-semibold">ML Validation</div>
            {mlReady && (
              <div className={`text-xs px-2 py-1 rounded-full font-semibold uppercase tracking-wide ${mlBadgeClass}`}>{mlBadgeText}</div>
            )}
          </div>
          <div className="mt-2 text-sm text-slate-700 dark:text-slate-300">
            <div>ML predicted crop: <span className="font-semibold capitalize">{mlResult?.predictedCrop || '—'}</span></div>
            <div>Confidence: <span className="font-semibold">{confidencePct !== null ? `${confidencePct}%` : '—'}</span></div>
            {mlError && (
              <div className="mt-1 text-xs text-amber-600">ML service unavailable.</div>
            )}
          </div>
        </div>
        <div className="mt-3 text-sm text-slate-600 dark:text-slate-300">
          <div className="font-semibold">Inputs used</div>
          <pre className="text-xs bg-slate-100 dark:bg-slate-800 p-2 rounded mt-1">{JSON.stringify(rec.inputUsed, null, 2)}</pre>
        </div>
      </div>
    </div>
  )
}

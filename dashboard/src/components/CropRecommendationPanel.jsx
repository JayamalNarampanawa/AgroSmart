import React from 'react'
import useRecommendationData from '../hooks/useRecommendationData'
import HologramCard from './ui/HologramCard'

export default function CropRecommendationPanel({ mlResult, mlError }) {
  const rec = useRecommendationData()

  const best = rec?.recommendedCrop
  const top3 = Array.isArray(rec?.top3)
    ? rec.top3
    : Object.entries(rec?.scores || {}).map(([c, s]) => ({ crop: c, score: s })).sort((a, b) => a.score - b.score).slice(0, 3)
  const matchLevel = rec?.matchLevel || "Unknown"
  const reasons = Array.isArray(rec?.reasons) ? rec.reasons : []
  const badgeText = matchLevel === "Unknown" ? "Unknown" : `${matchLevel} Match`
  const badgeClass = matchLevel === "Good"
    ? "bg-emerald-600 text-white"
    : matchLevel === "Moderate"
      ? "bg-amber-500 text-white"
      : matchLevel === "Poor"
        ? "bg-red-600 text-white"
        : "bg-slate-500 text-white"

  const mlReady = !!(mlResult?.predictedCrop && typeof mlResult?.confidence === 'number')
  const mlValidated = mlReady && mlResult.predictedCrop === best && mlResult.confidence >= 0.6
  const mlBadgeClass = mlValidated ? "bg-emerald-600 text-white" : "bg-amber-500 text-white"
  const mlBadgeText = mlValidated ? "Validated by ML" : "ML result differs - review recommended"
  const confidencePct = mlReady ? (mlResult.confidence * 100).toFixed(2) : null

  if (!rec) return (
    <div className="text-slate-400">No recommendation yet</div>
  )

  return (
    <HologramCard className="p-6">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <div className="text-xs uppercase tracking-[0.2em] text-slate-400">Recommendation</div>
          <div className="text-lg font-semibold">Explainable Recommendation (Primary)</div>
          <div className="text-xs text-slate-400 mt-1">Rule-based similarity from sensor vs ideal crop conditions</div>
        </div>
        <div className="flex items-center gap-2">
          <div className={`text-xs px-2.5 py-1 rounded-full font-semibold uppercase tracking-wide ${badgeClass}`}>{badgeText}</div>
          <div className="text-sm px-2.5 py-1 rounded-full bg-indigo-600 text-white capitalize">{best}</div>
        </div>
      </div>

      <div className="mt-4 grid gap-5 lg:grid-cols-[1.4fr_0.8fr]">
        <div>
          <div className="text-sm text-slate-300">Why this crop?</div>
          {reasons.length === 0 ? (
            <div className="mt-2 text-sm text-slate-400">No explanation available.</div>
          ) : (
            <ul className="mt-3 space-y-2 text-sm text-slate-200">
              {reasons.map((r, i) => (
                <li key={i} className="flex items-start gap-2">
                  <span className="mt-1 h-1.5 w-1.5 rounded-full bg-emerald-400"></span>
                  <span>{r}</span>
                </li>
              ))}
            </ul>
          )}
        </div>
        <div className="rounded-xl border border-white/8 bg-white/3 p-4">
          <div className="text-xs uppercase tracking-widest text-slate-400">Top 3</div>
          <ul className="mt-3 space-y-2 text-sm">
            {top3.map((t, i) => (
              <li key={i} className="flex items-center justify-between capitalize">
                <span>{i + 1}. {t.crop}</span>
                <span className="text-slate-300">{t.score === null ? 'N/A' : String(Math.round(t.score * 100) / 100)}</span>
              </li>
            ))}
          </ul>
        </div>
      </div>

      <div className="mt-5 rounded-xl border border-white/8 bg-white/3 p-4">
        <div className="flex flex-wrap items-center justify-between gap-2">
          <div>
            <div className="font-semibold">ML Validation (Secondary)</div>
            <div className="text-xs text-slate-400">Random Forest model confirms the primary recommendation</div>
          </div>
          {mlReady && (
            <div className={`text-xs px-2.5 py-1 rounded-full font-semibold uppercase tracking-wide ${mlBadgeClass}`}>{mlBadgeText}</div>
          )}
        </div>
        <div className="mt-2 text-sm text-slate-200">
          <div>ML predicted crop: <span className="font-semibold capitalize">{mlResult?.predictedCrop || '-'}</span></div>
          <div>Confidence: <span className="font-semibold">{confidencePct !== null ? `${confidencePct}%` : '-'}</span></div>
          {mlError && (
            <div className="mt-1 text-xs text-amber-300">ML service unavailable.</div>
          )}
        </div>
      </div>

      <div className="mt-4 text-sm text-slate-300">
        <div className="font-semibold">Inputs used</div>
        <pre className="text-xs bg-slate-950/70 border border-white/8 p-3 rounded-xl mt-2 overflow-auto">{JSON.stringify(rec.inputUsed, null, 2)}</pre>
      </div>
    </HologramCard>
  )
}

import React from 'react'
import { soilWetnessPercent } from '../utils/soilMoisture'
import useSoilMoistureSettings from '../hooks/useSoilMoistureSettings'
import { buildTips, simplifyReason } from '../utils/farmerText'
import HologramCard from './ui/HologramCard'

function computeRainTrend(history){
  if(!history || history.length < 4) return 'steady'
  const last = history.slice(-3).reduce((a,b)=>a + (b.rainfall || 0), 0) / 3
  const prev = history.slice(-6, -3).reduce((a,b)=>a + (b.rainfall || 0), 0) / 3
  if(last - prev > 0.2) return 'rising'
  if(prev - last > 0.2) return 'falling'
  return 'steady'
}

function badgeClass(matchLevel){
  if(matchLevel === 'Good') return 'bg-emerald-600 text-white'
  if(matchLevel === 'Moderate') return 'bg-amber-500 text-white'
  if(matchLevel === 'Poor') return 'bg-red-600 text-white'
  return 'bg-slate-500 text-white'
}

export default function FinalResultCard({ rec, mlResult, mlError, current, weather, weatherHistory }){
  if(!rec) return null
  const soilConfig = useSoilMoistureSettings()
  const wetnessPercent = soilWetnessPercent(current?.soilMoisture, soilConfig.wetMin, soilConfig.dryMax)
  const rainTrend = computeRainTrend(weatherHistory)
  const rainfallNow = typeof weather?.rainfall === 'number' ? weather.rainfall : 0

  const primaryCrop = rec?.recommendedCrop || rec?.bestCrop || '-'
  const mlAvailable = !!(mlResult?.predictedCrop && typeof mlResult?.confidence === 'number')
  const mlPredicted = mlResult?.predictedCrop || '-'
  const mlConfidence = mlAvailable ? Math.round(mlResult.confidence * 100) : null
  const agreement = mlAvailable ? (mlPredicted === primaryCrop ? 'Agrees' : 'Differs') : 'Unavailable'

  let decisionStatus = 'Primary Preferred'
  if(!mlAvailable) decisionStatus = 'Primary Only'
  else if(mlPredicted === primaryCrop) decisionStatus = 'Confirmed'

  const reasons = (Array.isArray(rec?.reasons) ? rec.reasons : [])
    .map(r=>simplifyReason(r, primaryCrop))
    .filter(Boolean)

  const tips = buildTips({
    wetnessPercent,
    temperature: current?.temperature ?? null,
    humidity: current?.humidity ?? null,
    rainTrend,
    rainfallNow
  })

  return (
    <HologramCard className="p-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <div className="text-xs uppercase tracking-[0.2em] text-slate-400">Final Result</div>
          <div className="text-lg font-semibold">Final Result (Decision Summary)</div>
        </div>
        <div className="text-xs px-2.5 py-1 rounded-full bg-white/10 border border-white/10 uppercase tracking-wide font-semibold">{decisionStatus}</div>
      </div>

      <div className="mt-4">
        <div className="text-sm text-slate-300">What to grow now</div>
        <div className="text-2xl font-semibold mt-1 capitalize">What to grow now: {primaryCrop}</div>
        {!mlAvailable && (
          <div className="mt-2 text-xs text-amber-300">ML validation unavailable; showing primary explainable recommendation.</div>
        )}
        {mlAvailable && mlPredicted !== primaryCrop && (
          <div className="mt-2 text-xs text-slate-300">
            ML suggests <span className="font-semibold capitalize">{mlPredicted}</span>, but primary explainable recommendation favors <span className="font-semibold capitalize">{primaryCrop}</span> due to closer environmental match.
          </div>
        )}
      </div>

      <div className="mt-5 grid gap-5 lg:grid-cols-3">
        <div className="rounded-xl border border-white/8 bg-white/3 p-4">
          <div className="text-sm font-semibold">Why this crop?</div>
          {reasons.length === 0 ? (
            <div className="mt-2 text-xs text-slate-400">No explanation available.</div>
          ) : (
            <ul className="mt-3 space-y-2 text-sm text-slate-200">
              {reasons.map((r,i)=>(
                <li key={i} className="flex items-start gap-2">
                  <span className="mt-1 h-1.5 w-1.5 rounded-full bg-emerald-400"></span>
                  <span>{r}</span>
                </li>
              ))}
            </ul>
          )}
        </div>

        <div className="rounded-xl border border-white/8 bg-white/3 p-4">
          <div className="text-sm font-semibold">Quick tips (based on sensor + weather)</div>
          {tips.length === 0 ? (
            <div className="mt-2 text-xs text-slate-400">No tips available.</div>
          ) : (
            <ul className="mt-3 space-y-2 text-sm text-slate-200">
              {tips.map((t,i)=>(
                <li key={i} className="flex items-start gap-2">
                  <span className="mt-1 h-1.5 w-1.5 rounded-full bg-sky-400"></span>
                  <span>{t}</span>
                </li>
              ))}
            </ul>
          )}
        </div>

        <div className="rounded-xl border border-white/8 bg-white/3 p-4">
          <div className="text-sm font-semibold">Validation snapshot</div>
          <div className="mt-3 text-sm text-slate-200 space-y-2">
            <div className="flex items-center justify-between gap-2">
              <span>Primary match</span>
              <span className={`text-xs px-2 py-1 rounded-full font-semibold uppercase tracking-wide ${badgeClass(rec?.matchLevel)}`}>
                {rec?.matchLevel || 'Unknown'}
              </span>
            </div>
            <div className="text-xs text-slate-400">Score: {rec?.bestScore ?? '-'}</div>
            <div className="pt-2 border-t border-white/8">
              <div className="flex items-center justify-between gap-2">
                <span>ML prediction</span>
                <span className="text-xs px-2 py-1 rounded-full bg-white/10 border border-white/10 uppercase tracking-wide">{agreement}</span>
              </div>
              <div className="mt-1">Crop: <span className="font-semibold capitalize">{mlPredicted}</span></div>
              <div>Confidence: <span className="font-semibold">{mlConfidence == null ? '--' : `${mlConfidence}%`}</span></div>
            </div>
          </div>
          {mlError && (
            <div className="mt-2 text-xs text-amber-300">ML service unavailable.</div>
          )}
        </div>
      </div>
    </div>
  )
}

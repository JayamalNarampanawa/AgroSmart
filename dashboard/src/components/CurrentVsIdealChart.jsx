import React from 'react'
import { ResponsiveContainer, BarChart, Bar, XAxis, YAxis, Tooltip, Legend } from 'recharts'
import useRecommendationData from '../hooks/useRecommendationData'
import { CROP_PATTERNS } from '../ai/cropPatterns'

export default function CurrentVsIdealChart(){
  const rec = useRecommendationData()
  if(!rec) return (
    <div className="text-slate-400">No recommendation available</div>
  )

  const crop = rec.recommendedCrop
  const pattern = crop ? CROP_PATTERNS[crop] : null
  if(!crop || !pattern){
    return (
      <div className="text-slate-400">No recommendation available</div>
    )
  }

  const input = rec.inputUsed || {}
  const features = [
    { key: "N", name: "Nitrogen (N)" },
    { key: "P", name: "Phosphorus (P)" },
    { key: "K", name: "Potassium (K)" },
    { key: "temperature", name: "Temperature" },
    { key: "humidity", name: "Humidity" },
    { key: "ph", name: "pH" },
    { key: "rainfall", name: "Rainfall" }
  ]

  const data = features.map(({ key, name })=>{
    const current = typeof input[key] === "number" ? input[key] : null
    const ideal = typeof pattern[key] === "number" ? pattern[key] : null
    return { name, current, ideal }
  })

  return (
    <div>
      <div className="text-xs uppercase tracking-[0.2em] text-slate-400">Benchmark</div>
      <div className="font-semibold mb-3">Current vs Ideal ({crop})</div>
      <div className="chart-3d rounded-xl border border-white/8 bg-slate-950/50 p-3">
        <ResponsiveContainer width="100%" height={300}>
          <BarChart data={data}>
            <XAxis dataKey="name" />
            <YAxis />
            <Tooltip />
            <Legend />
            <Bar dataKey="current" name="Current" fill="#3b82f6" />
            <Bar dataKey="ideal" name="Ideal" fill="#10b981" />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </div>
  )
}

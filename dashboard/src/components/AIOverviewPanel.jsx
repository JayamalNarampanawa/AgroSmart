import React from 'react'

export default function AIOverviewPanel({ aiResult, status, lastRunAt }){
  if(!aiResult) return (
    <div className="p-4 rounded-lg shadow-md bg-white dark:bg-slate-800">AI engine idle — waiting for data.</div>
  )

  const top = aiResult.topCrop
  const conf = aiResult.scores ? aiResult.scores[top] : (aiResult.scores?.[top] ?? 0)

  return (
    <div className="p-4 rounded-lg shadow-md bg-gradient-to-r from-white to-slate-50 dark:from-slate-800 dark:to-slate-900">
      <div className="flex items-center justify-between">
        <div>
          <div className="text-sm font-semibold">AI Engine: Client-side (No Cloud)</div>
          <div className="text-xs text-slate-500">AI Crop Growth Insights (Kaggle Historical Comparison)</div>
        </div>
        <div className="text-right">
          <div className="text-sm font-semibold">Top: <span className="capitalize">{top}</span></div>
          <div className="text-xs text-slate-500">Confidence: {conf ?? '--'}</div>
        </div>
      </div>
      <div className="mt-3 text-sm text-slate-700 dark:text-slate-300">{aiResult.missingFeatures?.length ? `Missing: ${aiResult.missingFeatures.join(', ')}` : 'All key features present'}</div>
      {lastRunAt && <div className="mt-2 text-xs text-slate-400">Last run: {new Date(lastRunAt).toLocaleString()}</div>}
    </div>
  )
}

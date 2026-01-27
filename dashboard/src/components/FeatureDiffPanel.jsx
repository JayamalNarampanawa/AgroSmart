import React from 'react'

export default function FeatureDiffPanel({ diffs = {}, crop }){
  if(!diffs || Object.keys(diffs).length === 0) return null

  return (
    <div className="p-4 rounded-lg shadow-md bg-white dark:bg-slate-800">
      <div className="font-semibold mb-2">Compared to Kaggle historical mean for <span className="capitalize">{crop}</span></div>
      <div className="text-sm text-slate-700 dark:text-slate-300">
        {Object.entries(diffs).map(([k,v])=> (
          <div key={k} className="flex justify-between">
            <div className="capitalize">{k}</div>
            <div>{v === null ? 'N/A' : `${v}`}</div>
          </div>
        ))}
      </div>
    </div>
  )
}

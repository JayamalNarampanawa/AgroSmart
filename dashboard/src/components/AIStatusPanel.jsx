import React from 'react'

export default function AIStatusPanel({ insight, loading, engineName, lastRunAt, historyCount }){
  const updatedAt = insight?.timestamp ? new Date(insight.timestamp).toLocaleString() : null
  const soilBadge = insight ? (insight.soilStatus === 'Dry' ? 'Dry' : 'Optimal') : 'Waiting'
  const heatRisk = insight?.riskFlags?.heatRisk
  const lowLight = insight?.riskFlags?.lowLight
  const irrigation = insight?.irrigationAdvice

  if(loading) return (
    <div className="holo-panel p-4 rounded-lg shadow-md bg-gradient-to-r from-slate-50 to-white dark:from-slate-800 dark:to-slate-900">
      <div className="animate-pulse space-y-2">
        <div className="h-6 bg-slate-200 dark:bg-slate-700 rounded w-1/3" />
        <div className="h-4 bg-slate-200 dark:bg-slate-700 rounded w-1/2" />
        <div className="h-4 bg-slate-200 dark:bg-slate-700 rounded w-full" />
      </div>
    </div>
  )

  if(!insight) return (
    <div className="holo-panel p-4 rounded-lg shadow-md bg-white dark:bg-slate-800">
      <div className="text-sm text-slate-600 dark:text-slate-300">Waiting for AI resultsâ€¦</div>
    </div>
  )

  return (
    <div className="holo-panel p-4 rounded-lg shadow-md bg-gradient-to-r from-white to-slate-50 dark:from-slate-800 dark:to-slate-900">
      <div className="flex items-center justify-between">
        <div className="text-sm font-semibold flex items-center gap-2">
          <span className="holo-indicator" />
          AI Status: <span className="text-indigo-600">Active</span>
        </div>
        <div className="flex items-center gap-3">
          <div className="text-xs text-slate-500">Last: {updatedAt}</div>
          {engineName && <div className="text-xs text-slate-500 px-2 py-1 rounded bg-slate-100 dark:bg-slate-700">{engineName}</div>}
        </div>
      </div>
      <div className="mt-3 space-y-2">
        <div className="flex items-center gap-2">
          <span className={`px-2 py-1 rounded-full text-xs ${soilBadge==='Dry'? 'bg-red-100 text-red-700' : 'bg-green-100 text-green-700'}`}>{soilBadge}</span>
          {heatRisk && <span className="px-2 py-1 rounded-full text-xs bg-amber-100 text-amber-800">Heat Risk</span>}
          {lowLight && <span className="px-2 py-1 rounded-full text-xs bg-blue-100 text-blue-800">Low Light</span>}
        </div>
        <div>
          <span className={`px-2 py-1 rounded-full text-sm ${irrigation==='ON'?'bg-red-600 text-white':'bg-green-600 text-white'}`}>Irrigation: {irrigation ?? 'Monitor'}</span>
        </div>
        <div className="mt-2 text-sm text-slate-700 dark:text-slate-300">{insight.summary}</div>
        {lastRunAt && <div className="mt-2 text-xs text-slate-500">AI last run: {new Date(lastRunAt).toLocaleString()}</div>}
        <div className="mt-1 text-xs text-slate-400">Using historical samples: {historyCount ?? 0}</div>
      </div>
    </div>
  )
}

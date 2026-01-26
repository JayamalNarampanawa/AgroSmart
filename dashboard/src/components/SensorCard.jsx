import React from 'react'

function Progress({ value }){
  const pct = Math.min(100, Math.max(0, Math.round((value/4095)*100)))
  return (
    <div className="w-full bg-white/6 rounded-full h-2 overflow-hidden mt-2">
      <div className="h-2 progress-bg" style={{width: `${pct}%`}} />
    </div>
  )
}

function getSensorVisual(type, value){
  const v = Number(value)
  if(type === 'temperature'){
    if(isNaN(v)) return {icon:'', color:'#94a3b8', status:'--'}
    if(v > 30) return {icon: (
      <svg width="48" height="48" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M12 2v10" stroke="#ef4444" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/><path d="M7 12a5 5 0 0010 0V5a5 5 0 00-10 0v7z" fill="#ffedd5"/><path d="M12 22v-2" stroke="#ef4444" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/></svg>
    ), color:'#ef4444', status:'Hot'}
    if(v < 15) return {icon:(
      <svg width="48" height="48" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M12 2v10" stroke="#0ea5e9" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/><path d="M7 12a5 5 0 0010 0V5a5 5 0 00-10 0v7z" fill="#e0f2fe"/><path d="M12 22v-2" stroke="#0ea5e9" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/></svg>
    ), color:'#0ea5e9', status:'Cold'}
    return {icon:(
      <svg width="48" height="48" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M12 2v10" stroke="#10b981" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/><path d="M7 12a5 5 0 0010 0V5a5 5 0 00-10 0v7z" fill="#ecfdf5"/><path d="M12 22v-2" stroke="#10b981" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/></svg>
    ), color:'#10b981', status:'Normal'}
  }

  if(type === 'humidity'){
    if(isNaN(v)) return {icon:'', color:'#94a3b8', status:'--'}
    if(v < 30) return {icon:(
      <svg width="48" height="48" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M12 2s5 4 5 8a5 5 0 01-10 0c0-4 5-8 5-8z" fill="#fef3c7" stroke="#f59e0b"/></svg>
    ), color:'#f59e0b', status:'Low'}
    if(v > 60) return {icon:(
      <svg width="48" height="48" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M12 2s5 4 5 8a5 5 0 01-10 0c0-4 5-8 5-8z" fill="#e0f2fe" stroke="#0ea5e9"/></svg>
    ), color:'#0ea5e9', status:'High'}
    return {icon:(
      <svg width="48" height="48" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M12 2s5 4 5 8a5 5 0 01-10 0c0-4 5-8 5-8z" fill="#ecfeff" stroke="#06b6d4"/></svg>
    ), color:'#06b6d4', status:'Normal'}
  }

  if(type === 'soil'){
    if(isNaN(v)) return {icon:'', color:'#94a3b8', status:'--'}
    if(v > 2200) return {icon:(
      <svg width="48" height="48" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M12 3c2 3 5 3 6 6 1 3-1 6-6 12-5-6-7-9-6-12 1-3 4-3 6-6z" fill="#ffe8d6" stroke="#f97316"/></svg>
    ), color:'#f97316', status:'Dry'}
    if(v > 1200) return {icon:(
      <svg width="48" height="48" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M12 3c2 3 5 3 6 6 1 3-1 6-6 12-5-6-7-9-6-12 1-3 4-3 6-6z" fill="#ecfdf5" stroke="#10b981"/></svg>
    ), color:'#10b981', status:'Optimal'}
    return {icon:(
      <svg width="48" height="48" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M12 3c2 3 5 3 6 6 1 3-1 6-6 12-5-6-7-9-6-12 1-3 4-3 6-6z" fill="#e0f2fe" stroke="#0ea5e9"/></svg>
    ), color:'#0ea5e9', status:'Wet'}
  }

  if(type === 'light'){
    if(isNaN(v)) return {icon:'', color:'#94a3b8', status:'--'}
    if(v < 200) return {icon:(
      <svg width="48" height="48" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><circle cx="12" cy="12" r="4" fill="#cbd5e1"/><path d="M12 2v2M12 20v2M4.2 4.2l1.4 1.4M18.4 18.4l1.4 1.4M2 12h2M20 12h2M4.2 19.8l1.4-1.4M18.4 5.6l1.4-1.4" stroke="#94a3b8" strokeWidth="1" strokeLinecap="round"/></svg>
    ), color:'#94a3b8', status:'Low'}
    if(v > 2000) return {icon:(
      <svg width="48" height="48" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><circle cx="12" cy="12" r="5" fill="#fff6d6"/><path d="M12 1v3M12 20v3M4 4l2 2M18 18l2 2M1 12h3M20 12h3M4 20l2-2M18 6l2-2" stroke="#fbbf24" strokeWidth="1" strokeLinecap="round"/></svg>
    ), color:'#fbbf24', status:'Bright'}
    return {icon:(
      <svg width="48" height="48" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><circle cx="12" cy="12" r="5" fill="#fff"/><path d="M12 2v3M12 19v3M4 4l2 2M18 18l2 2" stroke="#ffd166" strokeWidth="1" strokeLinecap="round"/></svg>
    ), color:'#ffd166', status:'Normal'}
  }

  return {icon:'', color:'#94a3b8', status:'--'}
}

export default function SensorCard({ title, value, unit, type }){
  const nice = value === '--' ? value : `${value}${unit}`
  const visual = getSensorVisual(type, value)

  return (
    <div className="card card-hover p-4 rounded-lg shadow flex flex-col">
      <div className="flex items-center justify-between">
        <div>
          <div className="text-sm text-slate-400">{title}</div>
          <div className={`text-2xl font-semibold ${value !== '--' ? 'value-pulse' : ''}`}>{nice}</div>
        </div>
        <div className="flex items-center gap-3">
          <div style={{width:56, height:56}} className="rounded-full flex items-center justify-center bg-black/10">
            {visual.icon}
          </div>
        </div>
      </div>
      {type === 'soil' && value !== '--' && <Progress value={Number(value)} />}
      <div className="mt-3 flex items-center justify-between text-xs">
        <div className="text-muted">Updated: <span className="text-slate-300">live</span></div>
        <div className="px-2 py-1 rounded text-xs" style={{background: visual.color, color: '#001'}}>{visual.status}</div>
      </div>
    </div>
  )
}

import React, { useMemo } from 'react'
import { motion } from 'framer-motion'
import useMotionPreferences from '../hooks/useMotionPreferences.jsx'

function dayKey(ts){
  const d = new Date(ts)
  return `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`
}

function dayLabel(ts){
  const d = new Date(ts)
  const today = new Date()
  const tomorrow = new Date()
  tomorrow.setDate(today.getDate() + 1)
  if(d.toDateString() === today.toDateString()) return 'Today'
  if(d.toDateString() === tomorrow.toDateString()) return 'Tomorrow'
  return d.toLocaleDateString([], { weekday: 'short', month: 'short', day: 'numeric' })
}

function pickIcon(day){
  if(day.totalRain > 0.2) return 'rain'
  const main = day.mostCommonMain
  if(main === 'Clear') return 'sun'
  if(main === 'Clouds') return 'cloud'
  if(main === 'Thunderstorm') return 'storm'
  if(main === 'Snow') return 'snow'
  return 'cloud'
}

function impactText(totalRain){
  if(totalRain >= 12) return 'Soil moisture likely to improve; reduce irrigation.'
  if(totalRain >= 3) return 'Light rain expected; monitor soil before irrigating.'
  return 'Dry day expected; irrigation may be needed.'
}

function Icon({ type }){
  if(type === 'sun'){
    return (
      <svg width="28" height="28" viewBox="0 0 24 24" fill="none">
        <circle cx="12" cy="12" r="4.5" fill="#fde68a" stroke="#f59e0b" strokeWidth="1.2"/>
        <path d="M12 2v3M12 19v3M4.5 4.5l2.2 2.2M17.3 17.3l2.2 2.2M2 12h3M19 12h3M4.5 19.5l2.2-2.2M17.3 6.7l2.2-2.2" stroke="#f59e0b" strokeWidth="1.2" strokeLinecap="round"/>
      </svg>
    )
  }
  if(type === 'rain'){
    return (
      <svg width="28" height="28" viewBox="0 0 24 24" fill="none">
        <path d="M7 16h10a4 4 0 0 0 0-8 6 6 0 0 0-11.3 1.8A3.5 3.5 0 0 0 7 16z" fill="#bae6fd" stroke="#38bdf8" strokeWidth="1.1"/>
        <path d="M8 18l-1 3M12 18l-1 3M16 18l-1 3" stroke="#38bdf8" strokeWidth="1.4" strokeLinecap="round"/>
      </svg>
    )
  }
  if(type === 'storm'){
    return (
      <svg width="28" height="28" viewBox="0 0 24 24" fill="none">
        <path d="M7 16h10a4 4 0 0 0 0-8 6 6 0 0 0-11.3 1.8A3.5 3.5 0 0 0 7 16z" fill="#e2e8f0" stroke="#94a3b8" strokeWidth="1.1"/>
        <path d="M12 17l-2.5 4H12l-1 3" stroke="#f59e0b" strokeWidth="1.4" strokeLinecap="round" strokeLinejoin="round"/>
      </svg>
    )
  }
  if(type === 'snow'){
    return (
      <svg width="28" height="28" viewBox="0 0 24 24" fill="none">
        <path d="M7 16h10a4 4 0 0 0 0-8 6 6 0 0 0-11.3 1.8A3.5 3.5 0 0 0 7 16z" fill="#f1f5f9" stroke="#94a3b8" strokeWidth="1.1"/>
        <path d="M9 19h.01M12 19h.01M15 19h.01" stroke="#94a3b8" strokeWidth="2" strokeLinecap="round"/>
      </svg>
    )
  }
  return (
    <svg width="28" height="28" viewBox="0 0 24 24" fill="none">
      <path d="M7 16h10a4 4 0 0 0 0-8 6 6 0 0 0-11.3 1.8A3.5 3.5 0 0 0 7 16z" fill="#e2e8f0" stroke="#94a3b8" strokeWidth="1.1"/>
    </svg>
  )
}

export default function WeatherForecastPanel({ forecast = [] }){
  const { enabled, reducedMotion } = useMotionPreferences()
  const allowMotion = enabled && !reducedMotion

  const days = useMemo(()=>{
    if(!forecast.length) return []
    const map = {}
    forecast.forEach(p=>{
      const key = dayKey(p.ts)
      if(!map[key]) map[key] = { ts: p.ts, points: [], totalRain: 0, mainCounts: {} }
      map[key].points.push(p)
      map[key].totalRain += (p.rainfall || 0)
      const main = p.weatherMain || 'Clouds'
      map[key].mainCounts[main] = (map[key].mainCounts[main] || 0) + 1
    })
    return Object.values(map).sort((a,b)=>a.ts - b.ts).slice(0, 6).map(d=>{
      const entries = Object.entries(d.mainCounts)
      const mostCommonMain = entries.sort((a,b)=>b[1]-a[1])[0]?.[0] || 'Clouds'
      return {
        ...d,
        mostCommonMain,
        label: dayLabel(d.ts),
        icon: pickIcon({ totalRain: d.totalRain, mostCommonMain })
      }
    })
  }, [forecast])

  if(days.length === 0){
    return <div className="text-xs text-slate-400">No forecast data available yet.</div>
  }

  return (
    <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
      {days.map((d, i)=>(
        <motion.div
          key={d.label + i}
          className="rounded-xl border border-white/8 bg-white/3 p-3"
          initial={allowMotion ? { opacity: 0, y: 8 } : false}
          animate={allowMotion ? { opacity: 1, y: 0 } : false}
          transition={{ duration: 0.35, delay: i * 0.05 }}
        >
          <div className="flex items-center justify-between">
            <div className="text-xs uppercase tracking-widest text-slate-400">{d.label}</div>
            <div className="h-8 w-8 flex items-center justify-center rounded-full bg-white/5">
              <Icon type={d.icon} />
            </div>
          </div>
          <div className="mt-2 text-sm font-semibold">{d.totalRain.toFixed(1)} mm</div>
          <div className="text-xs text-slate-300">{d.totalRain > 0.2 ? 'Rain likely' : 'No rain expected'}</div>
          <div className="mt-2 text-xs text-slate-400">{impactText(d.totalRain)}</div>
        </motion.div>
      ))}
    </div>
  )
}

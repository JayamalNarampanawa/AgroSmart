import React, { useEffect, useState } from 'react'
import { motion } from 'framer-motion'
import Tilt from 'react-parallax-tilt'
import useMotionPreferences from '../hooks/useMotionPreferences.jsx'
import useSoilMoistureSettings from '../hooks/useSoilMoistureSettings'
import { soilWetnessPercent } from '../utils/soilMoisture'

function Progress({ pct }){
  const safe = typeof pct === 'number' ? Math.min(100, Math.max(0, Math.round(pct))) : 0
  return (
    <div className="w-full bg-white/6 rounded-full h-2 overflow-hidden mt-2">
      <div className="h-2 progress-static" style={{width: `${safe}%`}} />
    </div>
  )
}

function getSensorVisual(type, value, soilWetness){
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
    const wetness = typeof soilWetness === 'number' ? soilWetness : (isNaN(v) ? null : v)
    if(wetness === null || wetness === undefined || Number.isNaN(wetness)) return {icon:'', color:'#94a3b8', status:'--'}
    if(wetness < 30) return {icon:(
      <svg width="48" height="48" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M12 3c2 3 5 3 6 6 1 3-1 6-6 12-5-6-7-9-6-12 1-3 4-3 6-6z" fill="#ffe8d6" stroke="#f97316"/></svg>
    ), color:'#f97316', status:'Dry'}
    if(wetness < 70) return {icon:(
      <svg width="48" height="48" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M12 3c2 3 5 3 6 6 1 3-1 6-6 12-5-6-7-9-6-12 1-3 4-3 6-6z" fill="#ecfdf5" stroke="#10b981"/></svg>
    ), color:'#10b981', status:'Optimal'}
    return {icon:(
      <svg width="48" height="48" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M12 3c2 3 5 3 6 6 1 3-1 6-6 12-5-6-7-9-6-12 1-3 4-3 6-6z" fill="#e0f2fe" stroke="#0ea5e9"/></svg>
    ), color:'#0ea5e9', status:'Wet'}
  }

  if(type === 'light'){
    if(isNaN(v)) return {icon:'', color:'#94a3b8', status:'--'}
    if(v < 200) return {icon:(
      <svg width="48" height="48" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
        <circle cx="12" cy="12" r="5" fill="#fff6d6" stroke="#fbbf24" strokeWidth="1.2"/>
        <path d="M12 1v3M12 20v3M4 4l2 2M18 18l2 2M1 12h3M20 12h3M4 20l2-2M18 6l2-2" stroke="#fbbf24" strokeWidth="1.2" strokeLinecap="round"/>
      </svg>
    ), color:'#fbbf24', status:'Bright'}
    if(v > 2000) return {icon:(
      <svg width="48" height="48" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path d="M15 3a7 7 0 100 14 6.5 6.5 0 01-6-9.5A7 7 0 0015 3z" fill="#0f172a" stroke="#94a3b8" strokeWidth="1.2"/>
        <circle cx="17.5" cy="6.5" r="1" fill="#94a3b8"/>
        <circle cx="19" cy="9.5" r="0.7" fill="#94a3b8"/>
      </svg>
    ), color:'#94a3b8', status:'Dark'}
    return {icon:(
      <svg width="48" height="48" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
        <circle cx="12" cy="12" r="4" fill="#fff3c4" stroke="#facc15" strokeWidth="1.2"/>
        <path d="M12 3v2M12 19v2M5 5l1.6 1.6M17.4 17.4l1.6 1.6M3 12h2M19 12h2" stroke="#facc15" strokeWidth="1.2" strokeLinecap="round"/>
      </svg>
    ), color:'#ffd166', status:'Normal'}
  }

  return {icon:'', color:'#94a3b8', status:'--'}
}

export default function SensorCard({ title, value, unit, type }){
  const nice = value === '--' ? value : `${value}${unit}`
  const soilConfig = useSoilMoistureSettings()
  const soilWetness = type === 'soil' ? soilWetnessPercent(value, soilConfig.wetMin, soilConfig.dryMax) : null
  const visual = getSensorVisual(type, value, soilWetness)
  const { enabled, reducedMotion } = useMotionPreferences()
  const allowMotion = enabled && !reducedMotion
  const [pulse, setPulse] = useState(false)

  useEffect(() => {
    if(value === '--') return
    setPulse(true)
    const t = setTimeout(() => setPulse(false), 700)
    return () => clearTimeout(t)
  }, [value])

  const card = (
    <motion.div
      className="sensor-card-3d p-5"
      animate={allowMotion ? { y: [0, -4, 0] } : undefined}
      transition={allowMotion ? { duration: 4.5, ease: 'easeInOut', repeat: Infinity } : undefined}
    >
      <div className="flex items-center justify-between">
        <div>
          <div className="text-xs uppercase tracking-[0.2em] text-slate-400">{title}</div>
          <div className={`text-3xl font-semibold mt-2 ${pulse ? 'value-pulse' : ''}`}>{nice}</div>
        </div>
        <div className="flex items-center gap-3">
          <div style={{width:64, height:64}} className="rounded-2xl flex items-center justify-center bg-white/5 ring-1 ring-white/10">
            {visual.icon}
          </div>
        </div>
      </div>
      {type === 'soil' && value !== '--' && <Progress pct={soilWetness} />}
      <div className="mt-4 flex items-center justify-between text-xs sensor-footer">
        <div className="text-muted">Updated: <span className="text-slate-200">live</span></div>
        <div className="px-2.5 py-1 rounded-full text-[11px] font-semibold uppercase tracking-wide" style={{background: visual.color, color: '#001'}}>{visual.status}</div>
      </div>
    </motion.div>
  )

  return (
    allowMotion ? (
      <Tilt
        tiltMaxAngleX={8}
        tiltMaxAngleY={8}
        glareEnable
        glareMaxOpacity={0.18}
        glareColor="#7dd3fc"
        glarePosition="all"
        transitionSpeed={1200}
        className="sensor-tilt"
      >
        {card}
      </Tilt>
    ) : (
      card
    )
  )
}

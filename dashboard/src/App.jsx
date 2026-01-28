import React, { useEffect } from 'react'
import { Routes, Route, Navigate } from 'react-router-dom'
import Dashboard from './pages/Dashboard'
import ensureFarmProfileDefaults from './utils/ensureFarmProfileDefaults'
import ensureWeatherDefaults from './utils/ensureWeatherDefaults'

export default function App(){
  useEffect(()=>{
    // Ensure both farm profile and weather defaults exist on startup
    ;(async ()=>{
      try{
        await ensureFarmProfileDefaults()
      }catch(e){ console.error(e) }
      try{
        await ensureWeatherDefaults()
      }catch(e){ console.error(e) }
    })()
  }, [])
  return (
    <Routes>
      <Route path="/" element={<Dashboard />} />
      <Route path="*" element={<Navigate to="/" />} />
    </Routes>
  )
}

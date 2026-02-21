import React, { useEffect } from 'react'
import { Routes, Route, Navigate, useLocation } from 'react-router-dom'
import { AnimatePresence, motion } from 'framer-motion'
import Dashboard from './pages/Dashboard'
import ensureFarmProfileDefaults from './utils/ensureFarmProfileDefaults'
import ensureWeatherDefaults from './utils/ensureWeatherDefaults'
import updateRainfallFromApi from './utils/updateRainfallFromApi'
import useMotionPreferences from './hooks/useMotionPreferences.jsx'
import SensorTwinTest from './pages/SensorTwinTest'
import ArView from './pages/ArView'

const ExternalRedirect = ({ to }) => {
  useEffect(() => {
    if (!to) return
    const normalize = (url) => url.replace(/\/+$/, '')
    if (typeof window !== 'undefined') {
      const current = normalize(window.location.href)
      const target = normalize(to)
      // Avoid redirect loop when already at target (with or without trailing slash)
      if (current === target) return
      window.location.replace(to)
    }
  }, [to])
  return null
}


export default function App() {
  const location = useLocation()
  const defaultHome = '/dashboard'
  const { enabled, reducedMotion } = useMotionPreferences()
  const allowMotion = enabled && !reducedMotion

  useEffect(() => {
    // Ensure both farm profile and weather defaults exist on startup
    let rainfallIntervalId = null
      ; (async () => {
        try {
          await ensureFarmProfileDefaults()
        } catch (e) { console.error(e) }
        try {
          await ensureWeatherDefaults()
        } catch (e) { console.error(e) }
        try {
          await updateRainfallFromApi()
          rainfallIntervalId = setInterval(updateRainfallFromApi, 30 * 60 * 1000)
        } catch (e) { console.error(e) }
      })()
    return () => {
      if (rainfallIntervalId) {
        clearInterval(rainfallIntervalId)
      }
    }
  }, [])
  return (
    <AnimatePresence mode="wait">
      <motion.div
        key={location.pathname}
        initial={allowMotion ? { opacity: 0, y: 12 } : false}
        animate={allowMotion ? { opacity: 1, y: 0 } : false}
        exit={allowMotion ? { opacity: 0, y: -12 } : false}
        transition={{ duration: 0.35, ease: 'easeOut' }}
      >
        <Routes location={location}>
          <Route path="/dashboard" element={<Dashboard />} />
          <Route path="/twin" element={<SensorTwinTest />} />
          <Route path="/twin-test" element={<SensorTwinTest />} />
          <Route path="/ar" element={<ArView />} />
          <Route path="/" element={<Navigate to={defaultHome} replace />} />
          <Route path="*" element={<Navigate to={defaultHome} replace />} />
        </Routes>
      </motion.div>
    </AnimatePresence>
  )
}

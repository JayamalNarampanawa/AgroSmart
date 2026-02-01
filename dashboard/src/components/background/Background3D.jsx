import React, { useEffect } from 'react'
import { motion, useMotionValue, useSpring, useTransform } from 'framer-motion'
import useMotionPreferences from '../../hooks/useMotionPreferences.jsx'

export default function Background3D(){
  const { enabled, reducedMotion } = useMotionPreferences()
  const allowMotion = enabled && !reducedMotion

  const mx = useMotionValue(0)
  const my = useMotionValue(0)

  const sx = useSpring(mx, { stiffness: 30, damping: 20 })
  const sy = useSpring(my, { stiffness: 30, damping: 20 })

  const slowX = useTransform(sx, v => v * 20)
  const slowY = useTransform(sy, v => v * 20)
  const midX = useTransform(sx, v => v * 32)
  const midY = useTransform(sy, v => v * 32)
  const fastX = useTransform(sx, v => v * 48)
  const fastY = useTransform(sy, v => v * 48)

  useEffect(() => {
    if(!allowMotion) return
    function onMove(e){
      const x = (e.clientX / window.innerWidth) - 0.5
      const y = (e.clientY / window.innerHeight) - 0.5
      mx.set(x)
      my.set(y)
    }
    window.addEventListener('mousemove', onMove, { passive: true })
    return () => window.removeEventListener('mousemove', onMove)
  }, [allowMotion, mx, my])

  return (
    <div className={`bg-3d-root ${allowMotion ? 'bg-3d-animate' : 'bg-3d-static'}`}>
      <motion.div
        className="bg-3d-layer bg-3d-sky"
        style={allowMotion ? { x: slowX, y: slowY } : undefined}
      />
      <motion.div
        className="bg-3d-layer bg-3d-grid"
        style={allowMotion ? { x: midX, y: midY } : undefined}
      />
      <motion.div
        className="bg-3d-layer bg-3d-particles"
        style={allowMotion ? { x: fastX, y: fastY } : undefined}
      />
      <div className="bg-3d-vignette" />
    </div>
  )
}

import React from 'react'
import { motion, useScroll, useTransform } from 'framer-motion'
import useMotionPreferences from '../../hooks/useMotionPreferences.jsx'

export default function Scroll3D({ children, className = '' }){
  const ref = React.useRef(null)
  const { enabled, reducedMotion } = useMotionPreferences()
  const allowMotion = enabled && !reducedMotion

  const { scrollYProgress } = useScroll({
    target: ref,
    offset: ['start end', 'end start']
  })

  const y = useTransform(scrollYProgress, [0, 1], allowMotion ? [8, -18] : [0, 0])
  const rotateX = useTransform(scrollYProgress, [0, 1], allowMotion ? [2, -2] : [0, 0])
  const scale = useTransform(scrollYProgress, [0, 1], allowMotion ? [0.995, 1.005] : [1, 1])

  return (
    <motion.div
      ref={ref}
      className={className}
      style={allowMotion ? { y, rotateX, scale, transformStyle: 'preserve-3d' } : undefined}
    >
      {children}
    </motion.div>
  )
}

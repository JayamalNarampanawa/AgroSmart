import React from 'react'
import { motion, useInView } from 'framer-motion'
import useMotionPreferences from '../../hooks/useMotionPreferences.jsx'

export default function AnimatedSection({ children, className = '' }){
  const ref = React.useRef(null)
  const inView = useInView(ref, { once: true, margin: '-10% 0px -10% 0px' })
  const { enabled, reducedMotion } = useMotionPreferences()
  const allowMotion = enabled && !reducedMotion

  return (
    <motion.div
      ref={ref}
      className={className}
      initial={allowMotion ? { opacity: 0, y: 18, scale: 0.98, rotateX: 6 } : false}
      animate={allowMotion && inView ? { opacity: 1, y: 0, scale: 1, rotateX: 0 } : undefined}
      transition={{ duration: 0.7, ease: 'easeOut' }}
      style={allowMotion ? { transformStyle: 'preserve-3d' } : undefined}
    >
      {children}
    </motion.div>
  )
}

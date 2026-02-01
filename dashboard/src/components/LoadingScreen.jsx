import React from 'react'
import { createPortal } from 'react-dom'
import { motion } from 'framer-motion'
import AgroOrb3D from './hero/AgroOrb3D'
import iconUrl from '../assets/icon.jpeg'
import useMotionPreferences from '../hooks/useMotionPreferences.jsx'

export default function LoadingScreen({message='Loading dashboard...'}){
  const { enabled, reducedMotion } = useMotionPreferences()
  const allowMotion = enabled && !reducedMotion

  const statusLines = [
    'Connecting to Firebase...',
    'Syncing sensors...',
    'Calibrating analytics...',
    'Initializing AI engine...'
  ]

  const listVariants = {
    hidden: {},
    show: {
      transition: { staggerChildren: 0.45 }
    }
  }

  const itemVariants = {
    hidden: { opacity: 0, y: 8 },
    show: { opacity: 1, y: 0 }
  }

  const content = (
    <motion.div
      className="fixed inset-0 z-50 flex items-center justify-center"
      initial={allowMotion ? { opacity: 0 } : false}
      animate={allowMotion ? { opacity: 1 } : false}
      exit={allowMotion ? { opacity: 0, scale: 1.02 } : false}
      transition={{ duration: 0.45, ease: 'easeOut' }}
    >
      <div className="w-full h-full loading-3d-shell" />
      <div className="absolute inset-0 flex items-center justify-center">
        <motion.div
          className="loading-panel"
          initial={allowMotion ? { opacity: 0, y: 12, scale: 0.98, rotateX: 6 } : false}
          animate={allowMotion ? { opacity: 1, y: 0, scale: 1, rotateX: 0 } : false}
          transition={{ duration: 0.6, ease: 'easeOut' }}
          style={{ transformStyle: 'preserve-3d' }}
        >
          <div className="loading-header">
            <div className="loading-kicker">AgroSmart Booting...</div>
            <div className="loading-title">{message}</div>
          </div>
          <div className="loading-brand">
            <div className="loading-icon-shell">
              <img src={iconUrl} alt="AgroSmart" className="loading-icon-img" />
            </div>
            <div className="loading-brand-lines">
              <div className="loading-brand-name">AgroSmart Dashboard</div>
              <div className="loading-brand-sub">Real-time IoT Monitoring</div>
            </div>
          </div>
          <div className="loading-orb">
            <AgroOrb3D size="xl" />
          </div>
          <motion.ul
            className="loading-status"
            variants={allowMotion ? listVariants : undefined}
            initial={allowMotion ? 'hidden' : false}
            animate={allowMotion ? 'show' : false}
          >
            {statusLines.map((line) => (
              <motion.li key={line} variants={allowMotion ? itemVariants : undefined} className="loading-line">
                <span className="loading-dot" />
                {line}
              </motion.li>
            ))}
          </motion.ul>
          <div className="loading-progress">
            <div className="loading-progress-label">Welcome to AgroSmart</div>
            <div className="loading-progress-track">
              <motion.div
                className="loading-progress-bar"
                animate={allowMotion ? { width: ['12%', '100%'] } : { width: '65%' }}
                transition={allowMotion ? { duration: 7, ease: 'easeInOut', repeat: Infinity } : undefined}
              />
            </div>
          </div>
          <div className="loading-footnote">System status: ONLINE</div>
        </motion.div>
      </div>
    </motion.div>
  )

  if(typeof document === 'undefined') return content
  return createPortal(content, document.body)
}

/* small keyframe for progress bar - added in index.css */

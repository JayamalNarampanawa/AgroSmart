import React from 'react'
import { motion } from 'framer-motion'
import { Link } from 'react-router-dom'
import iconUrl from '../assets/icon.jpeg'
import StatusPill from './ui/StatusPill'
import AgroOrb3D from './hero/AgroOrb3D'
// Navbar no longer uses Firebase Auth (public dashboard)

export default function Navbar() {
  return (
    <motion.header
      className="sticky top-4 z-40"
      initial={{ opacity: 0, y: -10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.6, ease: 'easeOut' }}
    >
      <div className="glass-panel rounded-2xl px-4 py-4 md:px-6 md:py-5 flex items-center justify-end relative">
        <div className="absolute left-1/2 -translate-x-1/2 flex items-center gap-3">
          <div className="w-14 h-14 md:w-16 md:h-16 rounded-full overflow-hidden">
            <img src={iconUrl} alt="AgroSmart" className="w-full h-full object-cover" />
          </div>
          <div className="text-center">
            <div className="text-xl md:text-2xl font-semibold">AgroSmart Dashboard</div>
            <div className="text-xs md:text-sm text-slate-400">Real-time IoT Monitoring</div>
          </div>
        </div>
        <div className="flex items-center gap-3">
          <div className="hidden md:block">
            <AgroOrb3D size="sm" />
          </div>
          <StatusPill label="Live" tone="live" />
          <div className="hidden md:flex items-center gap-2 pl-3">
            <Link
              to="/twin"
              className="inline-flex items-center gap-1 rounded-lg border border-cyan-400/50 bg-cyan-500/10 px-3 py-2 text-xs font-semibold text-cyan-100 shadow-[0_0_12px_rgba(34,211,238,0.25)] transition-all duration-200 hover:scale-[1.02] hover:border-cyan-300/80 hover:bg-cyan-500/20"
            >
              AgroSmart 2.0
            </Link>
          </div>
        </div>
      </div>
    </motion.header>
  )
}

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
      className="sticky top-2 md:top-4 z-40"
      initial={{ opacity: 0, y: -10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.6, ease: 'easeOut' }}
    >
      <div className="glass-panel rounded-2xl px-4 py-3 md:px-6 md:py-5">
        <div className="flex flex-col items-center gap-3 md:flex-row md:items-center md:justify-between">
          <div className="flex items-center justify-center gap-3 text-center md:justify-start md:text-left">
            <div className="w-12 h-12 md:w-16 md:h-16 rounded-full overflow-hidden">
              <img src={iconUrl} alt="AgroSmart" className="w-full h-full object-cover" />
            </div>
            <div>
              <div className="text-lg md:text-2xl font-semibold leading-tight">AgroSmart Dashboard</div>
              <div className="text-[11px] md:text-sm text-slate-400 leading-tight">Real-time IoT Monitoring</div>
            </div>
          </div>
          <div className="flex items-center justify-center gap-3 md:justify-end md:gap-3">
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
              <Link
                to="/scada"
                className="inline-flex items-center gap-1 rounded-lg border border-emerald-300/60 bg-emerald-500/10 px-3 py-2 text-xs font-semibold text-emerald-100 shadow-[0_0_12px_rgba(16,185,129,0.22)] transition-all duration-200 hover:scale-[1.02] hover:border-emerald-200/80 hover:bg-emerald-500/20"
              >
                SCADA
              </Link>
            </div>
          </div>
        </div>
      </div>
    </motion.header>
  )
}

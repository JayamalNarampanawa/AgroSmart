import React from 'react'
import iconUrl from '../assets/icon.jpeg'
import StatusPill from './ui/StatusPill'
// Navbar no longer uses Firebase Auth (public dashboard)

export default function Navbar(){
  return (
    <header className="sticky top-4 z-40">
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
          <StatusPill label="Live" tone="live" />
        </div>
      </div>
    </header>
  )
}

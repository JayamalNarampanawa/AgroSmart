import React from 'react'
// Navbar no longer uses Firebase Auth (public dashboard)

export default function Navbar(){
  return (
    <header className="flex items-center justify-between p-4 md:p-6 card-hover card rounded-lg">
      <div className="flex items-center gap-4">
        <div className="flex items-center gap-3">
          <div className="w-12 h-12 flex items-center justify-center rounded-full bg-white/5 p-1 overflow-hidden">
            <img src="/src/assets/icon.jpeg" alt="AgroSmart" className="w-full h-full object-cover" />
          </div>
          <div>
            <div className="text-lg font-semibold">AgroSmart Dashboard</div>
            <div className="text-xs text-slate-400">Real-time IoT Monitoring</div>
          </div>
        </div>
      </div>
    </header>
  )
}

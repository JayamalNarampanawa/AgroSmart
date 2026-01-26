import React from 'react'
// Navbar no longer uses Firebase Auth (public dashboard)

export default function Navbar(){
  return (
    <header className="flex items-center justify-between p-4 md:p-6 card-hover card rounded-lg">
      <div className="flex items-center gap-4">
        <div className="flex items-center gap-3">
          <div className="w-12 h-12 flex items-center justify-center rounded-full bg-gradient-to-br from-agGreen to-agBlue p-1">
            <svg width="36" height="36" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
              <defs>
                <linearGradient id="lg" x1="0" x2="1">
                  <stop offset="0" stop-color="#10b981"/>
                  <stop offset="1" stop-color="#06b6d4"/>
                </linearGradient>
              </defs>
              <path d="M12 2C13.1 2 14 2.9 14 4V10C14 11.1 13.1 12 12 12C10.9 12 10 11.1 10 10V4C10 2.9 10.9 2 12 2Z" fill="url(#lg)" />
              <path d="M6 12C7.1 12 8 12.9 8 14V20C8 21.1 7.1 22 6 22C4.9 22 4 21.1 4 20V14C4 12.9 4.9 12 6 12Z" fill="#0ea5e9" fill-opacity="0.85" />
              <path d="M18 12C19.1 12 20 12.9 20 14V18C20 19.1 19.1 20 18 20C16.9 20 16 19.1 16 18V14C16 12.9 16.9 12 18 12Z" fill="#16a34a" fill-opacity="0.95" />
            </svg>
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

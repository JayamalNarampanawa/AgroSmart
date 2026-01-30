import React from 'react'
import iconUrl from '../assets/icon.jpeg'

export default function LoadingScreen({message='Loading dashboard...'}){
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center backdrop-blur-sm">
      <div className="w-full h-full wallpaper opacity-90"></div>
      <div className="absolute flex flex-col items-center gap-4">
        <div className="w-28 h-28 rounded-full bg-white/10 flex items-center justify-center mx-auto overflow-hidden">
          <img src={iconUrl} alt="AgroSmart" className="w-full h-full object-cover" />
        </div>
        <div className="text-lg font-semibold text-slate-200">{message}</div>
        <div className="mt-4">
          <div className="h-1 w-64 bg-white/6 rounded overflow-hidden">
            <div className="h-1 progress-bg animate-[progress_2s_linear_infinite]" style={{width:'40%'}}></div>
          </div>
        </div>
      </div>
    </div>
  )
}

/* small keyframe for progress bar - added in index.css */

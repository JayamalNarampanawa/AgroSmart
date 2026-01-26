import React from 'react'

export default function LoadingScreen({message='Loading dashboard...'}){
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center backdrop-blur-sm">
      <div className="w-full h-full wallpaper opacity-90"></div>
      <div className="absolute flex flex-col items-center gap-4">
        <div className="w-24 h-24 rounded-full flex items-center justify-center bg-gradient-to-br from-agGreen to-agBlue shadow-lg animate-pulse">
          <div className="text-2xl font-bold text-black">AS</div>
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

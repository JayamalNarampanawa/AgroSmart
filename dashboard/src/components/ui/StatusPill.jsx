import React from 'react'

const tones = {
  live: 'bg-emerald-500/20 text-emerald-200 border-emerald-400/30',
  info: 'bg-sky-500/20 text-sky-200 border-sky-400/30',
  warn: 'bg-amber-500/20 text-amber-200 border-amber-400/30',
  neutral: 'bg-white/8 text-slate-200 border-white/10'
}

export default function StatusPill({ label, tone = 'neutral' }){
  return (
    <span className={`inline-flex items-center gap-2 rounded-full border px-3 py-1 text-xs font-semibold uppercase tracking-wide ${tones[tone] || tones.neutral}`}>
      <span className="h-1.5 w-1.5 rounded-full bg-current" />
      {label}
    </span>
  )
}

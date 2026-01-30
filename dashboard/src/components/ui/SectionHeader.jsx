import React from 'react'

export default function SectionHeader({ title, subtitle, right, eyebrow = 'Section' }){
  return (
    <div className="flex items-center justify-between gap-4">
      <div>
        {eyebrow && <div className="text-xs uppercase tracking-[0.2em] text-slate-400">{eyebrow}</div>}
        <div className="text-lg font-semibold text-slate-100">{title}</div>
        {subtitle && <div className="text-sm text-slate-400 mt-1">{subtitle}</div>}
      </div>
      {right ? <div className="shrink-0">{right}</div> : null}
    </div>
  )
}

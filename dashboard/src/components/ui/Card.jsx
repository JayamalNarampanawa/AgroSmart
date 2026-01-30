import React from 'react'

const base =
  'relative rounded-2xl border border-white/8 bg-slate-950/55 backdrop-blur-xl shadow-[0_12px_35px_rgba(2,6,23,0.45)]'
const hover =
  'transition-all duration-200 ease-out hover:-translate-y-1 hover:shadow-[0_18px_45px_rgba(2,6,23,0.6)]'

export default function Card({ children, className = '', hoverable = false }){
  return (
    <div className={`${base} ${hoverable ? hover : ''} ${className}`}>
      {children}
    </div>
  )
}

import React from 'react'

export default function HologramCard({ title, children, className = '' }) {
    return (
        <div className={`relative overflow-hidden rounded-2xl border border-cyan-400/20 bg-black/50 shadow-[0_0_22px_rgba(34,211,238,0.22)] ${className}`}>
            <div
                className="pointer-events-none absolute inset-0 mix-blend-screen"
                style={{
                    opacity: 0.15,
                    backgroundImage:
                        'radial-gradient(circle at 20% 20%, rgba(34,211,238,0.22), transparent 35%), radial-gradient(circle at 80% 10%, rgba(94,234,212,0.18), transparent 32%), radial-gradient(circle at 50% 90%, rgba(56,189,248,0.18), transparent 30%)',
                }}
            />
            <div
                className="pointer-events-none absolute inset-0"
                style={{
                    opacity: 0.12,
                    backgroundImage:
                        'repeating-linear-gradient(0deg, rgba(148,163,184,0.08), rgba(148,163,184,0.08) 1px, transparent 2px, transparent 4px)',
                }}
            />
            <div className="relative p-4 md:p-6">
                {title && <div className="mb-3 text-xs uppercase tracking-[0.28em] text-cyan-200/80">{title}</div>}
                {children}
            </div>
        </div>
    )
}

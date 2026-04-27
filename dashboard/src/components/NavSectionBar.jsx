import React, { useEffect, useMemo, useState } from 'react'
import { motion } from 'framer-motion'
import { Link } from 'react-router-dom'
import useMotionPreferences from '../hooks/useMotionPreferences.jsx'

export default function NavSectionBar({ sections = [] }) {
  const [activeId, setActiveId] = useState(sections[0]?.id || '')
  const ids = useMemo(() => sections.map(s => s.id), [sections])
  const { enabled, reducedMotion } = useMotionPreferences()
  const allowMotion = enabled && !reducedMotion

  useEffect(() => {
    if (!ids.length) return
    const elements = ids.map(id => document.getElementById(id)).filter(Boolean)
    if (!elements.length) return

    const observer = new IntersectionObserver((entries) => {
      const visible = entries.filter(e => e.isIntersecting).sort((a, b) => b.intersectionRatio - a.intersectionRatio)
      if (visible[0]?.target?.id) {
        setActiveId(visible[0].target.id)
      }
    }, { rootMargin: '-15% 0px -60% 0px', threshold: [0.1, 0.25, 0.5] })

    elements.forEach(el => observer.observe(el))
    return () => observer.disconnect()
  }, [ids])

  function scrollTo(id) {
    const el = document.getElementById(id)
    if (el) el.scrollIntoView({ behavior: 'smooth', block: 'start' })
  }

  return (
    <div className="sticky top-0 z-20 flex justify-center">
      <motion.div
        className="rounded-2xl border border-white/10 bg-gradient-to-r from-slate-950/80 via-slate-950/60 to-slate-900/60 backdrop-blur px-3 py-2 shadow-[0_18px_50px_rgba(0,0,0,0.35)] ring-1 ring-white/5"
        initial={allowMotion ? { opacity: 0, y: -8 } : false}
        animate={allowMotion ? { opacity: 1, y: 0 } : false}
        transition={{ duration: 0.45, ease: 'easeOut' }}
      >
        <div className="flex items-center gap-3">
          <div className="flex gap-2 overflow-x-auto no-scrollbar pr-1">
            {sections.map(s => {
              const isActive = s.id === activeId
              return (
                <motion.button
                  key={s.id}
                  onClick={() => scrollTo(s.id)}
                  whileHover={allowMotion ? { y: -1, scale: 1.02 } : undefined}
                  whileTap={allowMotion ? { scale: 0.98 } : undefined}
                  className={`whitespace-nowrap px-3.5 py-1.5 rounded-full text-xs font-semibold transition-all ${isActive
                      ? 'bg-sky-500 text-white shadow-[0_8px_24px_rgba(56,189,248,0.45)] ring-1 ring-sky-300/40'
                      : 'bg-white/6 text-slate-200 hover:bg-white/12 hover:text-white'
                    }`}
                >
                  {s.label}
                </motion.button>
              )
            })}
          </div>
          <Link
            to="/twin"
            className="inline-flex items-center gap-1 rounded-full border border-cyan-400/50 bg-cyan-500/10 px-3.5 py-1.5 text-xs font-semibold text-cyan-100 shadow-[0_0_12px_rgba(34,211,238,0.25)] transition-all duration-200 hover:scale-[1.02] hover:border-cyan-300/80 hover:bg-cyan-500/20"
          >
            AgroSmart 2.0
          </Link>
        </div>
      </motion.div>
    </div>
  )
}

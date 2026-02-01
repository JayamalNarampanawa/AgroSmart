import React from 'react'
import useMotionPreferences from '../../hooks/useMotionPreferences.jsx'

export default function PerspectiveStage({ children, className = '' }){
  const { enabled } = useMotionPreferences()

  return (
    <div className={`perspective-stage ${enabled ? 'perspective-on' : 'perspective-off'} ${className}`}>
      {children}
    </div>
  )
}

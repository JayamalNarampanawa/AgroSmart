import React, { createContext, useContext, useEffect, useMemo, useState } from 'react'
import { useReducedMotion } from 'framer-motion'

const MotionPreferencesContext = createContext({
  enabled: true,
  reducedMotion: false,
  setEnabled: () => {},
  toggle: () => {}
})

export function MotionPreferencesProvider({ children }){
  const reducedMotion = useReducedMotion()
  const [enabled, setEnabled] = useState(true)

  useEffect(() => {
    try{
      const stored = localStorage.getItem('agrosmart-3d')
      if(stored === null){
        setEnabled(!reducedMotion)
      }else{
        setEnabled(stored === 'on')
      }
    }catch(e){
      setEnabled(!reducedMotion)
    }
  }, [reducedMotion])

  useEffect(() => {
    try{
      localStorage.setItem('agrosmart-3d', enabled ? 'on' : 'off')
    }catch(e){}
  }, [enabled])

  const value = useMemo(() => ({
    enabled,
    reducedMotion,
    setEnabled,
    toggle: () => setEnabled(v => !v)
  }), [enabled, reducedMotion])

  return (
    <MotionPreferencesContext.Provider value={value}>
      {children}
    </MotionPreferencesContext.Provider>
  )
}

export default function useMotionPreferences(){
  return useContext(MotionPreferencesContext)
}

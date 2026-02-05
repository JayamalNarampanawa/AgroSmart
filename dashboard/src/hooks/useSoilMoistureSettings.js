import { useEffect, useState } from 'react'
import { ref, onValue } from 'firebase/database'
import { database } from '../firebase'
import { getSoilMoistureConfig } from '../utils/soilMoisture'

const DEFAULTS = getSoilMoistureConfig()

export default function useSoilMoistureSettings(){
  const [config, setConfig] = useState(DEFAULTS)

  useEffect(()=>{
    const settingsRef = ref(database, 'AgroSmart/settings')
    const unsub = onValue(settingsRef, snap=>{
      const v = snap.val()
      setConfig(getSoilMoistureConfig(v))
    }, err=>{
      console.error('settings read error', err)
      setConfig(DEFAULTS)
    })
    return ()=>{ try{ unsub() }catch(e){} }
  }, [])

  return config
}

import { useEffect, useRef } from 'react'
import useSensorData from './useSensorData'
import { ref, push, update } from 'firebase/database'
import { database } from '../firebase'

export default function useAnalyticsAppender({enabled = true, minInterval = 10000} = {}){
  const { current } = useSensorData()
  const lastHashRef = useRef(null)
  const lastTimeRef = useRef(0)

  useEffect(()=>{
    if(!enabled) return
    if(!current) return

    const now = Date.now()
    if(now - lastTimeRef.current < minInterval) return

    // create a simple hash to dedupe identical payloads
    const h = `${current.temperature ?? ''}|${current.humidity ?? ''}|${current.soilMoisture ?? ''}|${current.pumpStatus ? 1 : 0}`
    if(h === lastHashRef.current) return

    lastHashRef.current = h
    lastTimeRef.current = now

    const record = {
      source: 'sensor',
      temperature: current.temperature ?? null,
      humidity: current.humidity ?? null,
      rainfall: current.rainfall ?? null,
      ph: current.ph ?? null,
      soilMoisture: current.soilMoisture ?? null,
      pumpStatus: current.pumpStatus ?? null,
      timestamp: current.timestamp ?? now
    }

    // use multi-path update to push many records safely (generate a key then set)
    try{
      const listRef = ref(database, 'AgroSmart/analytics/timeseries')
      const newRef = push(listRef)
      const key = newRef.key
      const updates = {}
      updates[`/AgroSmart/analytics/timeseries/${key}`] = record
      update(ref(database, '/'), updates).catch(err=>{
        console.error('[useAnalyticsAppender] update error', err)
      })
    }catch(e){
      console.error('[useAnalyticsAppender] push error', e)
    }

  },[current, enabled, minInterval])
}

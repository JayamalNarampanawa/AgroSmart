import { useEffect, useState } from 'react'
import { onValue, ref } from 'firebase/database'
import { database } from '../firebase'

const DEFAULT_DATA = {
  temperature: 24,
  humidity: 60,
  soilMoisture: 48,
  lightLevel: 40,
  irrigationStatus: false
}

const toNumber = (v, fallback) => {
  const n = Number(v)
  return Number.isFinite(n) ? n : fallback
}

const parseIrrigationStatus = (payload = {}) => {
  const candidates = [
    payload.irrigationStatus,
    payload.irrigation,
    payload.pumpStatus,
    payload.pump,
    payload.relay
  ]
  const val = candidates.find((v)=> v !== undefined && v !== null)
  if(typeof val === 'boolean') return val
  if(typeof val === 'number') return val === 1
  if(typeof val === 'string') return val.trim().toLowerCase() === 'on'
  return false
}

export default function useAgroSmartLiveData(){
  const [data, setData] = useState(DEFAULT_DATA)
  const [connected, setConnected] = useState(false)

  useEffect(()=>{
    const dataRef = ref(database, '/AgroSmart/currentData')
    const fallbackTimer = setTimeout(()=> setConnected(false), 7000)

    const unsubscribe = onValue(dataRef, (snapshot)=>{
      const val = snapshot.val() || {}
      const next = {
        temperature: toNumber(val.temperature, DEFAULT_DATA.temperature),
        humidity: toNumber(val.humidity, DEFAULT_DATA.humidity),
        soilMoisture: toNumber(val.soilMoisture, DEFAULT_DATA.soilMoisture),
        lightLevel: toNumber(val.lightLevel, DEFAULT_DATA.lightLevel),
        irrigationStatus: parseIrrigationStatus(val)
      }
      setData(next)
      setConnected(true)
      clearTimeout(fallbackTimer)
    }, (error)=>{
      console.error('Digital Twin listener error', error)
      setConnected(false)
    })

    return ()=>{
      clearTimeout(fallbackTimer)
      unsubscribe()
    }
  }, [])

  return { data, connected }
}

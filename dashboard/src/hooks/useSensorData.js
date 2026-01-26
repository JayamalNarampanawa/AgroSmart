import { useEffect, useState } from 'react'
import { ref, onValue, get } from 'firebase/database'
import { database } from '../firebase'

export default function useSensorData(){
  const [current, setCurrent] = useState(null)
  const [history, setHistory] = useState([])
  const [error, setError] = useState(null)
  const [isReady, setIsReady] = useState(false)

  function normalizeCurrent(val){
    if(!val) return null
    const t = val.temperature ?? val.Temperature ?? val.temp ?? val.Temp
    const h = val.humidity ?? val.Humidity ?? val.Hum
    const s = val.soilMoisture ?? val.SoilMoisture ?? val.soil ?? val.Soil
    const l = val.lightLevel ?? val.LightLevel ?? val.light ?? val.Light
    // pump / irrigation status may be boolean, string 'ON'/'OFF' or numeric
    let p = val.pumpStatus ?? val.pump ?? val.PumpStatus ?? val.Irrigation ?? val.irrigation
    if (typeof p === 'string') p = p.toLowerCase() === 'on' || p === '1' || p === 'true'
    p = Boolean(p)
    const ts = val.timestamp ?? val.time ?? val.ts ?? Date.now()
    return {
      temperature: typeof t === 'number' ? t : (t ? Number(t) : null),
      humidity: typeof h === 'number' ? h : (h ? Number(h) : null),
      soilMoisture: typeof s === 'number' ? s : (s ? Number(s) : null),
      lightLevel: typeof l === 'number' ? l : (l ? Number(l) : null),
      pumpStatus: p,
      timestamp: typeof ts === 'number' ? ts : Date.now()
    }
  }

  function normalizeHistoryItem(v){
    if(!v) return null
    const n = normalizeCurrent(v)
    if(!n) return null
    return {
      ...n,
      pumpStatus: n.pumpStatus ? 1 : 0
    }
  }

  useEffect(()=>{
    setError(null)
    // Listen to root path to detect structure mismatches easily
    const rootRef = ref(database, 'AgroSmart')
    const curRef = ref(database, 'AgroSmart/currentData')
    const histRef = ref(database, 'AgroSmart/history/logs')

    // real-time listeners for specific paths
    const unsubCur = onValue(curRef, snapshot=>{
      const val = snapshot.val()
      console.log('[useSensorData] onValue currentData:', val)
      const normalized = normalizeCurrent(val)
      console.log('[useSensorData] normalized currentData:', normalized)
      setCurrent(normalized)
      setIsReady(true)
    }, (err)=>{
      console.error('[useSensorData] onValue currentData error', err)
      setError(err)
    })

    const unsubHist = onValue(histRef, snapshot=>{
      const val = snapshot.val() || {}
      console.log('[useSensorData] onValue history count:', Object.keys(val).length)
      try{
        const arr = Object.values(val).map(v=>normalizeHistoryItem(v)).filter(Boolean)
        arr.sort((a,b)=>a.timestamp - b.timestamp)
        setHistory(arr)
        setIsReady(true)
      }catch(e){
        console.error('[useSensorData] history parse error', e)
        setError(e)
      }
    }, (err)=>{
      console.error('[useSensorData] onValue history error', err)
      setError(err)
    })

    // Also listen to root to inspect the whole AgroSmart object and derive data if sensors write to root
    const unsubRoot = onValue(rootRef, snapshot=>{
      const val = snapshot.val()
      console.log('[useSensorData] onValue AgroSmart root:', val)

      // If currentData path is empty but sensors write directly under AgroSmart, detect keys and derive current
      const hasSensorKeys = val && (
        val.Temperature !== undefined || val.temperature !== undefined ||
        val.Humidity !== undefined || val.humidity !== undefined ||
        val.SoilMoisture !== undefined || val.soilMoisture !== undefined ||
        val.Soil !== undefined || val.soil !== undefined ||
        val.LightLevel !== undefined || val.lightLevel !== undefined ||
        val.Light !== undefined || val.light !== undefined ||
        val.Irrigation !== undefined || val.Irrigation !== undefined
      )

      if(hasSensorKeys){
        const derived = normalizeCurrent(val)
        console.log('[useSensorData] derived currentData from AgroSmart root:', derived)
        setCurrent(derived)
        setIsReady(true)
      }

      // If history not present under expected path, try common alternatives
      const histCandidate = val && (val.history?.logs || val.history || val.logs || val.log || val.historyLogs)
      if(histCandidate && Object.keys(histCandidate).length > 0){
        try{
          const arr = Object.values(histCandidate).map(v=>normalizeHistoryItem(v)).filter(Boolean)
          arr.sort((a,b)=>a.timestamp - b.timestamp)
          console.log('[useSensorData] derived history from AgroSmart root, count=', arr.length)
          setHistory(arr)
          setIsReady(true)
        }catch(e){
          console.error('[useSensorData] deriving history from root failed', e)
        }
      }
    }, (err)=>{
      console.error('[useSensorData] onValue AgroSmart root error', err)
    })

    // one-time get to help debugging connectivity/permissions
    get(curRef).then(snap=>{
      console.log('[useSensorData] get currentData once:', snap.val())
    }).catch(err=>{
      console.error('[useSensorData] get currentData error', err)
      setError(err)
    })

    get(histRef).then(snap=>{
      console.log('[useSensorData] get history once count:', snap.exists() ? Object.keys(snap.val() || {}).length : 0)
    }).catch(err=>{
      console.error('[useSensorData] get history error', err)
      setError(err)
    })

    return ()=>{
      try{ unsubCur() }catch(e){}
      try{ unsubHist() }catch(e){}
      try{ unsubRoot() }catch(e){}
    }
  },[])

  return { current, history, error }
}

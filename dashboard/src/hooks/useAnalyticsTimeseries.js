import { useEffect, useState } from 'react'
import { ref, onValue, query, orderByChild, limitToLast, get } from 'firebase/database'
import { database } from '../firebase'

export default function useAnalyticsTimeseries({limit = 3000} = {}){
  const [data, setData] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  useEffect(()=>{
    setLoading(true)
    setError(null)
    try{
      const tsRef = ref(database, 'AgroSmart/analytics/timeseries')
      const q = query(tsRef, orderByChild('timestamp'), limitToLast(limit))
      const unsub = onValue(q, snap=>{
        const val = snap.val() || {}
        const arr = Object.values(val).map(v=>({
          ...v,
          // ensure numeric or null
          temperature: v.temperature == null ? null : Number(v.temperature),
          humidity: v.humidity == null ? null : Number(v.humidity),
          rainfall: v.rainfall == null ? null : Number(v.rainfall),
          ph: v.ph == null ? null : Number(v.ph),
          soilMoisture: v.soilMoisture == null ? null : Number(v.soilMoisture),
          pumpStatus: v.pumpStatus == null ? null : (v.pumpStatus === true || v.pumpStatus === 1 || v.pumpStatus === '1' || v.pumpStatus === 'true'),
          timestamp: v.timestamp == null ? null : Number(v.timestamp),
          source: v.source || 'sensor'
        }))
        arr.sort((a,b)=> (a.timestamp||0) - (b.timestamp||0))
        setData(arr)
        setLoading(false)
      }, err=>{
        setError(err)
        setLoading(false)
      })

      // initial one-time get to allow synchronous check outside of listener if needed
      get(q).catch(()=>{})

      return ()=>{
        try{ unsub() }catch(e){}
      }
    }catch(e){
      setError(e)
      setLoading(false)
    }
  },[limit])

  return { data, loading, error }
}

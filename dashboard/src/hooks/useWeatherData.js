import { useEffect, useState } from 'react'
import { ref, onValue, query, orderByChild, limitToLast } from 'firebase/database'
import { database } from '../firebase'

export default function useWeatherData({ historyLimit = 336 } = {}){
  const [weather, setWeather] = useState(null)
  const [history, setHistory] = useState([])
  const [forecast, setForecast] = useState([])

  useEffect(()=>{
    const weatherRef = ref(database, 'AgroSmart/weather')
    const unsub = onValue(weatherRef, snap=>{
      setWeather(snap.val())
    }, err=>{
      console.error('weather read error', err)
    })
    return ()=>{ try{ unsub() }catch(e){} }
  }, [])

  useEffect(()=>{
    const historyRef = query(
      ref(database, 'AgroSmart/weather/history'),
      orderByChild('ts'),
      limitToLast(historyLimit)
    )
    const unsub = onValue(historyRef, snap=>{
      const v = snap.val() || {}
      const rows = Object.entries(v).map(([id, item])=>({
        id,
        ts: Number(item?.ts ?? 0),
        rainfall: typeof item?.rainfall === 'number' ? item.rainfall : Number(item?.rainfall ?? 0),
        temperature: item?.temperature ?? null,
        humidity: item?.humidity ?? null,
        windSpeed: item?.windSpeed ?? null
      })).filter(r=>r.ts > 0).sort((a,b)=>a.ts - b.ts)
      setHistory(rows)
    }, err=>{
      console.error('weather history read error', err)
      setHistory([])
    })
    return ()=>{ try{ unsub() }catch(e){} }
  }, [historyLimit])

  useEffect(()=>{
    const forecastRef = ref(database, 'AgroSmart/weather/forecast')
    const unsub = onValue(forecastRef, snap=>{
      const v = snap.val() || {}
      const points = Array.isArray(v.points) ? v.points : []
      const rows = points.map((p, i)=>({
        id: `f-${i}`,
        ts: Number(p?.ts ?? 0),
        rainfall: typeof p?.rainfall === 'number' ? p.rainfall : Number(p?.rainfall ?? 0),
        temperature: p?.temperature ?? null,
        weatherMain: p?.weatherMain ?? null,
        weatherDesc: p?.weatherDesc ?? null,
        icon: p?.icon ?? null
      })).filter(r=>r.ts > 0).sort((a,b)=>a.ts - b.ts)
      setForecast(rows)
    }, err=>{
      console.error('weather forecast read error', err)
      setForecast([])
    })
    return ()=>{ try{ unsub() }catch(e){} }
  }, [])

  return { weather, history, forecast }
}

import { useEffect, useRef, useState } from 'react'
import { ref, push, update } from 'firebase/database'
import { database, auth } from '../firebase'
import { onAuthStateChanged } from 'firebase/auth'
import { computeSuitabilityFromSensor, computeInsight, pickTopCrop, buildRecommendations, aggregateHistory } from '../ai/computeAI'

// minimum interval between writes (ms)
const DEFAULT_MIN_INTERVAL = 10 * 1000

export default function useClientAIWriter(currentData, options = {}){
  const minInterval = options.minInterval ?? DEFAULT_MIN_INTERVAL
  const onlyWhenAuthenticated = options.onlyWhenAuthenticated ?? true
  const history = options.history ?? []
  const fallbackConditions = options.fallbackConditions ?? (currentData?.current_conditions ?? null)

  const lastHashRef = useRef(null)
  const lastRunAtRef = useRef(0)
  const [lastRunAt, setLastRunAt] = useState(null)
  const [error, setError] = useState(null)
  const [enabled, setEnabled] = useState(false)

  useEffect(()=>{
    // enabled only if auth is present (or option disabled)
    const check = ()=> setEnabled(!onlyWhenAuthenticated || Boolean(auth.currentUser))
    check()
    const unsub = onAuthStateChanged(auth, ()=> check())
    return ()=> unsub()
  }, [onlyWhenAuthenticated])

  useEffect(()=>{
    if(!enabled) return
    if(!currentData) return

    try{
      // simple required fields check
      const ts = currentData.timestamp ?? Date.now()
      const important = {
        temperature: currentData.temperature ?? null,
        humidity: currentData.humidity ?? null,
        // rainfall & ph may be under currentData or nested fallback object during development
        rainfall: (currentData.rainfall ?? (fallbackConditions && fallbackConditions.rainfall) ?? null),
        ph: (currentData.ph ?? (fallbackConditions && fallbackConditions.ph) ?? null),
        soilMoisture: currentData.soilMoisture ?? null,
        lightLevel: currentData.lightLevel ?? null,
        pumpStatus: currentData.pumpStatus ?? currentData.pump ?? false,
        timestamp: ts
      }

      const hash = JSON.stringify(important)

      const now = Date.now()
      // throttle
      if(now - lastRunAtRef.current < minInterval) return

      // dedupe: if same hash and same timestamp, skip
      if(lastHashRef.current === hash) return

      // proceed: reserve a new key for history log
      const logsRef = ref(database, '/AgroSmart/history/logs')
      const newLogRef = push(logsRef)
      const key = newLogRef.key

      // aggregate recent history and compute AI from aggregated sample
      const aggregatedSample = aggregateHistory(history, important)
      const insight = computeInsight(aggregatedSample)
      const { breakdown, totals } = computeSuitabilityFromSensor(aggregatedSample)
      const { topCrop, topScore } = pickTopCrop(totals)
      const recs = buildRecommendations(topCrop, insight, totals)

      const tsNum = Number(important.timestamp) || Date.now()

      const updates = {}
      updates[`/AgroSmart/history/logs/${key}`] = important
      updates['/AgroSmart/ai/currentInsight'] = { ...insight, timestamp: tsNum }
      updates['/AgroSmart/ai/suitability'] = { ...totals, basis: 'Rule-based v1', timestamp: tsNum }
      updates['/AgroSmart/ai/recommendations'] = { topCrop, actions: recs.actions, confidence: recs.confidence, timestamp: tsNum }
      updates[`/AgroSmart/ai/history/${key}`] = {
        input: important,
        insight: { ...insight, timestamp: tsNum },
        suitability: { ...totals, basis: 'Rule-based v1', timestamp: tsNum },
        recommendations: { topCrop, actions: recs.actions, confidence: recs.confidence, timestamp: tsNum }
      }

      // single multi-path update
      update(ref(database, '/'), updates).then(()=>{
        lastHashRef.current = hash
        lastRunAtRef.current = Date.now()
        setLastRunAt(lastRunAtRef.current)
      }).catch(e=>{
        setError(e)
      })

    }catch(e){
      setError(e)
    }

  }, [currentData, enabled, minInterval])

  return { enabled, lastRunAt, error }
}

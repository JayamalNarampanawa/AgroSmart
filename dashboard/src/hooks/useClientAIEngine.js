import { useEffect, useRef, useState } from 'react'
import { ref, update } from 'firebase/database'
import { database, auth } from '../firebase'
import { onAuthStateChanged } from 'firebase/auth'
import { computeSuitabilityForAllCrops } from '../ai/computeSuitability'

const DEFAULT_MIN_INTERVAL = 10 * 1000

export default function useClientAIEngine(currentData, options = {}){
  const minInterval = options.minInterval ?? DEFAULT_MIN_INTERVAL
  const writeBack = options.writeBack ?? true

  const lastHashRef = useRef(null)
  const lastRunRef = useRef(0)
  const [aiResult, setAiResult] = useState(null)
  const [status, setStatus] = useState('idle')
  const [lastRunAt, setLastRunAt] = useState(null)
  const [error, setError] = useState(null)
  const [enabled, setEnabled] = useState(!options.requireAuth)

  useEffect(()=>{
    if(options.requireAuth){
      const unsub = onAuthStateChanged(auth, (u)=> setEnabled(Boolean(u)))
      return ()=> unsub()
    }
  },[options.requireAuth])

  useEffect(()=>{
    if(!enabled) return
    if(!currentData) return

    try{
      const now = Date.now()
      if(now - lastRunRef.current < minInterval) return

      const hash = JSON.stringify(currentData)
      if(lastHashRef.current === hash) return

      setStatus('running')
      const result = computeSuitabilityForAllCrops(currentData)
      setAiResult(result)

      // prepare outputs
      const ts = Number(currentData.timestamp) || Date.now()
      const suitabilityOut = { ...result.scores, basis: 'Kaggle mean-distance v1', timestamp: ts, missingFeatures: result.missingFeatures }
      const summary = `Best match: ${result.topCrop} (confidence ${suitabilityOut[result.topCrop]}).`
      const insightOut = {
        timestamp: ts,
        summary,
        topCrop: result.topCrop,
        usedFeatures: result.usedFeatures,
        diffs: result.diffs[result.topCrop] ?? {},
        notes: result.missingFeatures.length? [`Missing features: ${result.missingFeatures.join(', ')}`] : []
      }
      const recommendationsOut = {
        topCrop: result.topCrop,
        confidence: suitabilityOut[result.topCrop] ?? 0,
        actions: [
          'Maintain temperature near historical average',
          'Adjust humidity towards crop optimum',
          'Monitor rainfall / water supply'
        ],
        timestamp: ts
      }

      // write back if allowed
      if(writeBack && auth.currentUser){
        const updates = {}
        updates['/AgroSmart/ai/suitability'] = suitabilityOut
        updates['/AgroSmart/ai/currentInsight'] = insightOut
        updates['/AgroSmart/ai/recommendations'] = recommendationsOut
        update(ref(database, '/'), updates).catch(e=>{
          console.error('AI write error', e)
        })
      }

      lastHashRef.current = hash
      lastRunRef.current = Date.now()
      setLastRunAt(lastRunRef.current)
      setStatus('ok')
    }catch(e){
      setError(e)
      setStatus('error')
    }

  }, [currentData, enabled, minInterval, writeBack])

  return { aiResult, status, lastRunAt, error }
}

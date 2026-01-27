import { useEffect, useState } from 'react'
import { ref, onValue } from 'firebase/database'
import { database } from '../firebase'

export default function useAIData(){
  const [insight, setInsight] = useState(null)
  const [suitability, setSuitability] = useState(null)
  const [recs, setRecs] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  useEffect(()=>{
    setError(null)
    setLoading(true)
    const insightRef = ref(database, 'AgroSmart/ai/currentInsight')
    const suitRef = ref(database, 'AgroSmart/ai/suitability')
    const recRef = ref(database, 'AgroSmart/ai/recommendations')

    const unsubInsight = onValue(insightRef, snap=>{
      setInsight(snap.val())
      setLoading(false)
    }, err=>{ setError(err); setLoading(false) })

    const unsubSuit = onValue(suitRef, snap=>{
      setSuitability(snap.val())
    }, err=>{ setError(err) })

    const unsubRec = onValue(recRef, snap=>{
      setRecs(snap.val())
    }, err=>{ setError(err) })

    return ()=>{
      try{ unsubInsight() }catch(e){}
      try{ unsubSuit() }catch(e){}
      try{ unsubRec() }catch(e){}
    }
  }, [])

  return { insight, suitability, recs, loading, error }
}

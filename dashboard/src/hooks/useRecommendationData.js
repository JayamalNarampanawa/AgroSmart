import { useEffect, useState } from 'react'
import { ref, onValue } from 'firebase/database'
import { database } from '../firebase'

export default function useRecommendationData(){
  const [rec, setRec] = useState(null)

  useEffect(()=>{
    const r = ref(database, 'AgroSmart/ai/recommendation')
    const unsub = onValue(r, snap=>{
      setRec(snap.val())
    }, err=>{
      console.error('recommendation read error', err)
    })
    return ()=>{ try{ unsub() }catch(e){} }
  }, [])

  return rec
}

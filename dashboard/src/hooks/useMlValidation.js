import { useEffect, useState } from 'react'
import { getMlPrediction } from '../services/mlService'

export default function useMlValidation(rec){
  const [mlResult, setMlResult] = useState(null)
  const [mlError, setMlError] = useState(null)

  useEffect(()=>{
    let alive = true
    const input = rec?.inputUsed
    const best = rec?.recommendedCrop
    if(!input || !best) return
    const payload = {
      N: input.N,
      P: input.P,
      K: input.K,
      temperature: input.temperature,
      humidity: input.humidity,
      rainfall: input.rainfall,
      ph: input.ph
    }

    getMlPrediction(payload).then(out=>{
      if(!alive) return
      setMlResult(out)
      setMlError(null)
    }).catch(err=>{
      if(!alive) return
      setMlResult(null)
      setMlError(err)
      console.error('ML prediction failed', err)
    })

    return ()=>{ alive = false }
  }, [rec?.recommendedCrop, rec?.inputUsed])

  return { mlResult, mlError }
}

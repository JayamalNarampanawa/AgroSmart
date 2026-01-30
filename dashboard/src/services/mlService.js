console.log(
  "ML API BASE URL:",
  import.meta.env.VITE_ML_API_BASE_URL
);
import { envConfig } from '../config/env'

const BASE_URL = envConfig.mlApiBaseUrl



export async function getMlPrediction(payload){
  const res = await fetch(`${BASE_URL}/predict`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload)
  })

  if(!res.ok){
    let details = ''
    try{
      const err = await res.json()
      if(err?.detail) details = `: ${err.detail}`
    }catch(e){}
    throw new Error(`ML API request failed with status ${res.status}${details}`)
  }

  const data = await res.json()
  return {
    predictedCrop: data.predictedCrop,
    confidence: data.confidence,
    probabilities: data.probabilities
  }
}

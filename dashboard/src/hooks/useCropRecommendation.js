import { useEffect, useRef } from 'react'
import { ref, onValue, set, serverTimestamp } from 'firebase/database'
import { database } from '../firebase'
import computeRecommendation from '../ai/computeRecommendation'

export default function useCropRecommendation(){
  const latest = useRef({ current: null, farm: null, weather: null })

  useEffect(()=>{
    const curRef = ref(database, 'AgroSmart/currentData')
    const farmRef = ref(database, 'AgroSmart/farmProfile')
    const weatherRef = ref(database, 'AgroSmart/weather')

    const handle = ()=>{
      const { current, farm, weather } = latest.current

      // compute only when all three exist
      if(!current || !farm || !weather) return

      // strict validation
      const temp = current.temperature
      const hum = current.humidity
      if(typeof temp !== 'number' || Number.isNaN(temp) || typeof hum !== 'number' || Number.isNaN(hum)){
        return
      }

      const N = farm.N
      const P = farm.P
      const K = farm.K
      if(typeof N !== 'number' || Number.isNaN(N) || typeof P !== 'number' || Number.isNaN(P) || typeof K !== 'number' || Number.isNaN(K)){
        return
      }

      const ph = (typeof farm.ph === 'number' && !Number.isNaN(farm.ph)) ? farm.ph : 6.5
      const rainfall = (typeof weather.rainfall === 'number' && !Number.isNaN(weather.rainfall)) ? weather.rainfall : 0

      // build normalized inputs
      const farmNorm = { N, P, K, ph }
      const weatherNorm = { rainfall }

      try{
        const out = computeRecommendation({ currentData: { temperature: temp, humidity: hum }, farmProfile: farmNorm, weather: weatherNorm })
        const payload = {
          recommendedCrop: out.bestCrop,
          scores: out.scores,
          top3: out.top3,
          inputUsed: out.inputUsed,
          updatedAt: serverTimestamp()
        }
        set(ref(database, 'AgroSmart/ai/recommendation'), payload).catch(e=>{
          console.error('write recommendation failed', e)
        })
      }catch(e){
        console.error('compute recommendation error', e)
      }
    }

    const unsubCur = onValue(curRef, snap=>{
      latest.current = { ...latest.current, current: snap.val() }
      handle()
    })
    const unsubFarm = onValue(farmRef, snap=>{
      latest.current = { ...latest.current, farm: snap.val() }
      handle()
    })
    const unsubWeather = onValue(weatherRef, snap=>{
      latest.current = { ...latest.current, weather: snap.val() }
      handle()
    })

    return ()=>{
      try{ unsubCur() }catch(e){}
      try{ unsubFarm() }catch(e){}
      try{ unsubWeather() }catch(e){}
    }
  }, [])
}

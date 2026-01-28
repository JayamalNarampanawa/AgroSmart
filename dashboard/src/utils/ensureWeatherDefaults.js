import { ref, get, set, serverTimestamp } from 'firebase/database'
import { database } from '../firebase'

export default async function ensureWeatherDefaults(){
  try{
    const wref = ref(database, 'AgroSmart/weather')
    const snap = await get(wref)
    if(!snap.exists()){
      await set(wref, { rainfall: 0, updatedAt: serverTimestamp() })
      console.log('Weather defaults created')
    }
  }catch(e){
    console.error('ensureWeatherDefaults error', e)
    throw e
  }
}

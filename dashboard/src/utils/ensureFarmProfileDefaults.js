import { ref, get, set, serverTimestamp } from 'firebase/database'
import { database } from '../firebase'

export default async function ensureFarmProfileDefaults(){
  try{
    const farmRef = ref(database, 'AgroSmart/farmProfile')
    const snap = await get(farmRef)
    if(!snap.exists()){
      await set(farmRef, {
        N: 0,
        P: 0,
        K: 0,
        ph: 6.5,
        phIsDefault: true,
        updatedAt: serverTimestamp()
      })
      console.log('Farm profile defaults created')
    }
  }catch(e){
    console.error('ensureFarmProfileDefaults error', e)
    throw e
  }
}

import { initializeApp } from 'firebase/app'
import { getAuth } from 'firebase/auth'
import { getDatabase } from 'firebase/database'
import { getAnalytics } from 'firebase/analytics'

// Firebase config provided by user
const firebaseConfig = {
  apiKey: "AIzaSyDTFHx8jKrkeXCwtGeBDQV29phYd2e_UdM",
  authDomain: "agro-smart-2026.firebaseapp.com",
  databaseURL: "https://agro-smart-2026-default-rtdb.firebaseio.com",
  projectId: "agro-smart-2026",
  storageBucket: "agro-smart-2026.firebasestorage.app",
  messagingSenderId: "668916133955",
  appId: "1:668916133955:web:2157ff3b8604a36e6e24f6",
  measurementId: "G-4QFC3679E7"
}

const app = initializeApp(firebaseConfig)
let analytics = null
try{
  analytics = getAnalytics(app)
}catch(e){
  console.warn('Firebase analytics not available in this environment', e)
}

// debug: confirm initialization in browser console
try{
  console.log('Firebase initialized. databaseURL=', firebaseConfig.databaseURL)
}catch(e){}

export const auth = getAuth(app)
export const database = getDatabase(app)
export { app, analytics }
export default app

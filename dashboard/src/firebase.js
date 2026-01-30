import { initializeApp } from 'firebase/app'
import { getAuth } from 'firebase/auth'
import { getDatabase } from 'firebase/database'
import { getAnalytics } from 'firebase/analytics'
import { envConfig } from './config/env'

// Firebase config provided by user
const firebaseConfig = envConfig.firebase

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

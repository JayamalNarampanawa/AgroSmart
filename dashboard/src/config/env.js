const raw = import.meta.env

const required = [
  'VITE_FIREBASE_API_KEY',
  'VITE_FIREBASE_AUTH_DOMAIN',
  'VITE_FIREBASE_DATABASE_URL',
  'VITE_FIREBASE_PROJECT_ID',
  'VITE_FIREBASE_STORAGE_BUCKET',
  'VITE_FIREBASE_MESSAGING_SENDER_ID',
  'VITE_FIREBASE_APP_ID'
]

const missing = required.filter(k=>!raw[k])
if(missing.length){
  console.error(`[AgroSmart] Missing required environment variables: ${missing.join(', ')}. Create .env.local based on .env.example.`)
  throw new Error('Missing required environment variables.')
}

const warnMissing = (keys, message)=>{
  const absent = keys.filter(k=>!raw[k])
  if(absent.length){
    console.warn(`[AgroSmart] ${message} Missing: ${absent.join(', ')}`)
  }
}

warnMissing(['VITE_OWM_API_KEY', 'VITE_LAT', 'VITE_LON'], 'OpenWeatherMap configuration incomplete.')

export const envConfig = {
  firebase: {
    apiKey: raw.VITE_FIREBASE_API_KEY,
    authDomain: raw.VITE_FIREBASE_AUTH_DOMAIN,
    databaseURL: raw.VITE_FIREBASE_DATABASE_URL,
    projectId: raw.VITE_FIREBASE_PROJECT_ID,
    storageBucket: raw.VITE_FIREBASE_STORAGE_BUCKET,
    messagingSenderId: raw.VITE_FIREBASE_MESSAGING_SENDER_ID,
    appId: raw.VITE_FIREBASE_APP_ID,
    measurementId: raw.VITE_FIREBASE_MEASUREMENT_ID || null
  },
  openWeather: {
    apiKey: raw.VITE_OWM_API_KEY || null,
    lat: raw.VITE_LAT || null,
    lon: raw.VITE_LON || null
  },
  mlApiBaseUrl: raw.VITE_ML_API_BASE_URL || 'http://127.0.0.1:8000'
}

export default envConfig

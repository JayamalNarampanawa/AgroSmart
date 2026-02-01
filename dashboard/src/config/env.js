const raw = import.meta.env

const warnMissing = (keys, message)=>{
  const absent = keys.filter(k=>!raw[k])
  if(absent.length){
    console.warn(`[AgroSmart] ${message} Missing: ${absent.join(', ')}`)
  }
}

const hasOpenWeatherKey = Boolean(raw.VITE_OPENWEATHER_API_KEY || raw.VITE_OWM_API_KEY)
if(!hasOpenWeatherKey || !raw.VITE_LAT || !raw.VITE_LON){
  const missing = [
    hasOpenWeatherKey ? null : 'VITE_OPENWEATHER_API_KEY',
    raw.VITE_LAT ? null : 'VITE_LAT',
    raw.VITE_LON ? null : 'VITE_LON'
  ].filter(Boolean)
  console.warn(`[AgroSmart] OpenWeatherMap configuration incomplete. Missing: ${missing.join(', ')}`)
}

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
    apiKey: raw.VITE_OPENWEATHER_API_KEY || raw.VITE_OWM_API_KEY || null,
    lat: raw.VITE_LAT || null,
    lon: raw.VITE_LON || null
  },
  mlApiBaseUrl: raw.VITE_ML_API_BASE_URL || 'http://127.0.0.1:8000'
}

export default envConfig

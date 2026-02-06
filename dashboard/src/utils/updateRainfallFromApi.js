import { ref, update, serverTimestamp, push, get } from "firebase/database"
import { database } from "../firebase"
import { envConfig } from "../config/env"

export default async function updateRainfallFromApi(){
  const apiKey = envConfig.openWeather.apiKey
  const lat = envConfig.openWeather.lat
  const lon = envConfig.openWeather.lon

  if(!apiKey || !lat || !lon){
    console.error("OpenWeatherMap env vars missing. Check VITE_OPENWEATHER_API_KEY/VITE_LAT/VITE_LON.")
    return
  }

  const url = `https://api.openweathermap.org/data/2.5/weather?lat=${encodeURIComponent(lat)}&lon=${encodeURIComponent(lon)}&appid=${encodeURIComponent(apiKey)}`
  const forecastUrl = `https://api.openweathermap.org/data/2.5/forecast?lat=${encodeURIComponent(lat)}&lon=${encodeURIComponent(lon)}&appid=${encodeURIComponent(apiKey)}`

  let response
  try{
    response = await fetch(url)
  }catch(e){
    console.error("OpenWeatherMap fetch failed.", e)
    return
  }

  if(!response.ok){
    console.error("OpenWeatherMap response not ok.", response.status, response.statusText)
    return
  }

  let data
  try{
    data = await response.json()
  }catch(e){
    console.error("OpenWeatherMap JSON parse failed.", e)
    return
  }

  const rain = data && data.rain ? data.rain : null
  const rainfall = typeof rain?.["1h"] === "number"
    ? rain["1h"]
    : (typeof rain?.["3h"] === "number" ? rain["3h"] : 0)
  const tempK = data?.main?.temp
  const temperature = typeof tempK === 'number' ? Math.round((tempK - 273.15) * 10) / 10 : null
  const humidity = typeof data?.main?.humidity === 'number' ? data.main.humidity : null
  const windSpeed = typeof data?.wind?.speed === 'number' ? data.wind.speed : null
  const description = Array.isArray(data?.weather) && data.weather[0]?.description ? data.weather[0].description : null

  try{
    await update(ref(database, "AgroSmart/weather"), {
      rainfall,
      temperature,
      humidity,
      windSpeed,
      description,
      source: "OpenWeatherMap",
      updatedAt: serverTimestamp()
    })

    // fetch forecast to show upcoming rain trend (5-day / 3-hour)
    let forecastList = []
    try{
      const forecastRes = await fetch(forecastUrl)
      if(forecastRes.ok){
        const forecastData = await forecastRes.json()
        const list = Array.isArray(forecastData?.list) ? forecastData.list : []
        forecastList = list.map(item=>{
          const ts = typeof item?.dt === 'number' ? item.dt * 1000 : Date.now()
          const rain = item?.rain
          const rainfall = typeof rain?.["3h"] === "number" ? rain["3h"] : 0
          const tempK = item?.main?.temp
          const temperature = typeof tempK === 'number' ? Math.round((tempK - 273.15) * 10) / 10 : null
          const weather0 = Array.isArray(item?.weather) ? item.weather[0] : null
          const weatherMain = weather0?.main ?? null
          const weatherDesc = weather0?.description ?? null
          const icon = weather0?.icon ?? null
          return { ts, rainfall, temperature, weatherMain, weatherDesc, icon }
        })
      }
    }catch(e){
      console.error("OpenWeatherMap forecast fetch failed.", e)
    }

    if(forecastList.length){
      await update(ref(database, "AgroSmart/weather/forecast"), {
        source: "OpenWeatherMap",
        updatedAt: serverTimestamp(),
        points: forecastList
      })
    }

    const historyRef = ref(database, "AgroSmart/weather/history")
    const ts = Date.now()
    await push(historyRef, { ts, rainfall, temperature, humidity, windSpeed })

    const snap = await get(historyRef)
    const items = snap.val() || {}
    const entries = Object.entries(items).map(([k, v])=>({
      key: k,
      ts: Number(v?.ts ?? 0)
    })).filter(r=>r.ts > 0).sort((a,b)=>a.ts - b.ts)
    const maxPoints = 336
    if(entries.length > maxPoints){
      const toRemove = entries.slice(0, entries.length - maxPoints)
      const updates = {}
      toRemove.forEach(e=>{ updates[`AgroSmart/weather/history/${e.key}`] = null })
      await update(ref(database), updates)
    }
  }catch(e){
    console.error("Failed to update rainfall in Firebase.", e)
  }
}

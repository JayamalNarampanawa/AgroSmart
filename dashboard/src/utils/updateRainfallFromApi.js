import { ref, update, serverTimestamp } from "firebase/database"
import { database } from "../firebase"
import { envConfig } from "../config/env"

export default async function updateRainfallFromApi(){
  const apiKey = envConfig.openWeather.apiKey
  const lat = envConfig.openWeather.lat
  const lon = envConfig.openWeather.lon

  if(!apiKey || !lat || !lon){
    console.error("OpenWeatherMap env vars missing. Check VITE_OWM_API_KEY/VITE_LAT/VITE_LON.")
    return
  }

  const url = `https://api.openweathermap.org/data/2.5/weather?lat=${encodeURIComponent(lat)}&lon=${encodeURIComponent(lon)}&appid=${encodeURIComponent(apiKey)}`

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

  try{
    await update(ref(database, "AgroSmart/weather"), {
      rainfall,
      source: "OpenWeatherMap",
      updatedAt: serverTimestamp()
    })
  }catch(e){
    console.error("Failed to update rainfall in Firebase.", e)
  }
}

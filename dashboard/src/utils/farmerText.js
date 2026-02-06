const FEATURE_LABELS = {
  temperature: 'Temperature',
  humidity: 'Humidity',
  rainfall: 'Rainfall',
  ph: 'Soil pH',
  N: 'Nitrogen',
  P: 'Phosphorus',
  K: 'Potassium'
}

function extractFeature(reason){
  const lower = reason.toLowerCase()
  return Object.keys(FEATURE_LABELS).find((k)=>lower.includes(k.toLowerCase())) || null
}

function extractIntensity(reason){
  if(/very different/i.test(reason)) return 'far'
  if(/\bdifferent\b/i.test(reason)) return 'off'
  if(/slightly different/i.test(reason)) return 'near'
  if(/close/i.test(reason)) return 'good'
  return 'near'
}

export function simplifyReason(reason, crop){
  if(!reason || typeof reason !== 'string') return null
  const featureKey = extractFeature(reason)
  const feature = featureKey ? FEATURE_LABELS[featureKey] : 'Conditions'
  const intensity = extractIntensity(reason)
  if(intensity === 'good' || intensity === 'near'){
    return `${feature} is close to the ideal range for ${crop}.`
  }
  if(intensity === 'off'){
    return `${feature} is a bit off, but still acceptable for ${crop}.`
  }
  return `${feature} differs from the ideal range, so monitor it for ${crop}.`
}

export function buildTips({ wetnessPercent, temperature, humidity, rainTrend, rainfallNow }){
  const tips = []

  if(typeof wetnessPercent === 'number'){
    if(wetnessPercent < 30){
      tips.push('Soil is dry; irrigate lightly and recheck in 30–60 minutes.')
    }else if(wetnessPercent > 75){
      tips.push('Soil is wet; avoid irrigating now to prevent root issues.')
    }else{
      tips.push('Soil moisture looks balanced; maintain current irrigation routine.')
    }
  }

  if(rainTrend === 'rising'){
    tips.push('Rain likely; delay irrigation if possible.')
  }else if(rainTrend === 'falling' && rainfallNow === 0){
    tips.push('No rain expected soon; plan irrigation accordingly.')
  }

  if(typeof temperature === 'number' && temperature >= 32){
    tips.push('High temperature detected; water early morning or late evening to reduce heat stress.')
  }

  if(typeof humidity === 'number' && humidity >= 80){
    tips.push('High humidity can increase fungal risk; ensure good airflow around crops.')
  }

  if(typeof humidity === 'number' && humidity <= 30){
    tips.push('Low humidity may stress plants; monitor for wilting and adjust irrigation.')
  }

  return tips.slice(0, 6)
}

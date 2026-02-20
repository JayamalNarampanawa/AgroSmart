const templates = {
  temperatureHigh: 'Consider shade/ventilation during peak sun hours.',
  temperatureLow: 'Consider protecting crops from cold; monitor night temperatures.',
  humidityLow: 'Consider misting/irrigation timing to raise humidity.',
  humidityHigh: 'Ventilate to reduce excess humidity and disease risk.',
  rainfallLow: 'Irrigation may be needed; monitor soil moisture trend.',
  rainfallHigh: 'Rainfall is high; monitor drainage to avoid waterlogging.',
  phOff: 'Soil pH may need adjustment (lime/organic matter) — verify with soil test.'
}

function classifyDelta(current, ideal, tolerance = 0) {
  if (current == null || ideal == null || Number.isNaN(current) || Number.isNaN(ideal)) return null
  const delta = current - ideal
  if (delta > tolerance) return 'high'
  if (delta < -tolerance) return 'low'
  return 'ok'
}

export function generateSuggestions({ current = {}, ideal = {}, keyFeatures = [] }) {
  const out = []

  // Temperature
  const tempState = classifyDelta(current.temperature, ideal.temperature, 0.8)
  if (tempState === 'high') out.push(templates.temperatureHigh)
  if (tempState === 'low') out.push(templates.temperatureLow)

  // Humidity
  const humState = classifyDelta(current.humidity, ideal.humidity, 3)
  if (humState === 'high') out.push(templates.humidityHigh)
  if (humState === 'low') out.push(templates.humidityLow)

  // Rainfall
  const rainState = classifyDelta(current.rainfall, ideal.rainfall, 5)
  if (rainState === 'high') out.push(templates.rainfallHigh)
  if (rainState === 'low') out.push(templates.rainfallLow)

  // pH
  const phState = classifyDelta(current.ph, ideal.ph, 0.2)
  if (phState && phState !== 'ok') out.push(templates.phOff)

  if (out.length === 0) return ['No actions available yet.']
  // Limit to 2 suggestions, prefer those related to key features if available
  if (keyFeatures.length === 0) return out.slice(0, 2)
  const prioritized = out.filter((s) => {
    return (
      (s.includes('temperature') && keyFeatures.includes('temperature')) ||
      (s.includes('humidity') && keyFeatures.includes('humidity')) ||
      (s.includes('rain') && keyFeatures.includes('rainfall')) ||
      (s.includes('pH') && keyFeatures.includes('ph'))
    )
  })
  const final = prioritized.concat(out).filter((v, i, a) => a.indexOf(v) === i)
  return final.slice(0, 2)
}

export default generateSuggestions

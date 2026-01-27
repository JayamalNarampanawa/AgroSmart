// Rule-based v1 AI computation utilities (client-side)

function clamp(n, min, max){
  return Math.max(min, Math.min(max, n))
}

function scoreRange(value, range, penaltyFactor=2.5){
  if(value === null || value === undefined) return 0
  const [min, max] = range
  if(value >= min && value <= max) return 100
  const dist = value < min ? (min - value) : (value - max)
  const score = Math.max(0, 100 - dist * penaltyFactor)
  return Math.round(score)
}

// Crop profiles include ranges for temperature, humidity, rainfall (mm), and pH.
// Tweak these constants as needed; they are used by rule-based v1 scoring.
const CROP_PROFILES = {
  kidneybeans: { temp: [18,28], humidity: [45,75], rainfall: [50,150], ph: [6.0,7.5] },
  mungbean:    { temp: [22,32], humidity: [40,70], rainfall: [75,200], ph: [6.5,7.8] },
  chickpea:    { temp: [15,25], humidity: [20,55], rainfall: [30,100], ph: [6.0,8.0] }
}

function computeSuitabilityFromSensor(sensor){
  const temp = sensor?.temperature ?? null
  const hum = sensor?.humidity ?? null
  const rainfall = sensor?.rainfall ?? null
  const ph = sensor?.ph ?? null

  // base weights; will renormalize if some features are missing
  const baseWeights = { temp: 0.30, humidity: 0.25, rainfall: 0.25, ph: 0.20 }

  const out = {}
  Object.keys(CROP_PROFILES).forEach(crop => {
    const profile = CROP_PROFILES[crop]

    const scores = {}
    const present = {}

    // compute per-feature scores
    scores.temp = scoreRange(temp, profile.temp)
    present.temp = (temp !== null && temp !== undefined)

    scores.humidity = scoreRange(hum, profile.humidity)
    present.humidity = (hum !== null && hum !== undefined)

    scores.rainfall = scoreRange(rainfall, profile.rainfall)
    present.rainfall = (rainfall !== null && rainfall !== undefined)

    scores.ph = scoreRange(ph, profile.ph)
    present.ph = (ph !== null && ph !== undefined)

    // renormalize weights to only include present features
    const activeWeights = Object.entries(baseWeights).filter(([k])=> present[k]).map(([,v])=>v)
    const weightSum = activeWeights.reduce((s,n)=>s+n,0) || 1

    // build weighted total
    let total = 0
    Object.keys(baseWeights).forEach(k=>{
      if(present[k]){
        const w = baseWeights[k] / weightSum
        total += (scores[k] || 0) * w
      }
    })
    total = Math.round(total)

    // build 'why' explanations: inside/outside and distance
    const why = []
    const checkFactor = (name, val, range) => {
      if(val === null || val === undefined) return
      const [min,max] = range
      if(val >= min && val <= max) why.push(`${name}: within range (${min}-${max})`)
      else if(val < min) why.push(`${name}: below range by ${Math.round(min - val)}`)
      else why.push(`${name}: above range by ${Math.round(val - max)}`)
    }
    checkFactor('temperature', temp, profile.temp)
    checkFactor('humidity', hum, profile.humidity)
    checkFactor('rainfall', rainfall, profile.rainfall)
    checkFactor('pH', ph, profile.ph)

    out[crop] = {
      scores,
      why,
      total
    }
  })
  const totals = Object.fromEntries(Object.entries(out).map(([k,v])=>[k,v.total]))
  return { breakdown: out, totals }
}

// Aggregate recent history entries and combine with current sample.
// history: array of items with temperature, humidity, soilMoisture, lightLevel, timestamp
function aggregateHistory(history = [], current = null, window = 20){
  if(!Array.isArray(history) || history.length === 0) return current
  const arr = history.slice(-window)
  const sum = { temperature:0, humidity:0, soilMoisture:0, lightLevel:0 }
  let count = 0
  for(const it of arr){
    if(it == null) continue
    if(typeof it.temperature === 'number') { sum.temperature += it.temperature }
    if(typeof it.humidity === 'number') { sum.humidity += it.humidity }
    if(typeof it.soilMoisture === 'number') { sum.soilMoisture += it.soilMoisture }
    if(typeof it.lightLevel === 'number') { sum.lightLevel += it.lightLevel }
    count++
  }
  const avg = {
    temperature: count? Math.round(sum.temperature / count * 10)/10 : (current?.temperature ?? null),
    humidity: count? Math.round(sum.humidity / count * 10)/10 : (current?.humidity ?? null),
    soilMoisture: count? Math.round(sum.soilMoisture / count) : (current?.soilMoisture ?? null),
    lightLevel: count? Math.round(sum.lightLevel / count) : (current?.lightLevel ?? null)
  }
  // merge with current where available (give current slight precedence)
  return {
    temperature: (current?.temperature ?? avg.temperature),
    humidity: (current?.humidity ?? avg.humidity),
    soilMoisture: (current?.soilMoisture ?? avg.soilMoisture),
    lightLevel: (current?.lightLevel ?? avg.lightLevel)
  }
}

function computeInsight(sensor){
  const temperature = sensor?.temperature ?? null
  const soil = sensor?.soilMoisture ?? null
  const light = sensor?.lightLevel ?? null

  const soilDry = (soil !== null && soil !== undefined) ? (soil > 2200) : false
  const heatRisk = (temperature !== null && temperature !== undefined) ? (temperature > 35) : false
  const lowLight = (light !== null && light !== undefined) ? (light < 500) : false

  const irrigationAdvice = soilDry ? 'ON' : 'OFF'
  const soilStatus = soilDry ? 'Dry' : 'Optimal'
  const summary = soilDry ? 'Soil appears dry. Irrigation recommended.' : 'Soil moisture looks healthy. Continue monitoring.'

  return {
    soilStatus,
    irrigationAdvice,
    riskFlags: { heatRisk, lowLight, sensorStale: false },
    summary
  }
}

function pickTopCrop(totals){
  const entries = Object.entries(totals)
  entries.sort((a,b)=>b[1]-a[1])
  return { topCrop: entries[0] ? entries[0][0] : null, topScore: entries[0] ? entries[0][1] : 0 }
}

function buildRecommendations(topCrop, insight, totals){
  const actions = []
  if(insight.soilStatus === 'Dry') actions.push('Irrigation recommended: soil moisture is low.')
  else actions.push('Soil moisture is within acceptable range.')
  if(insight.riskFlags.heatRisk) actions.push('High temperature detected — consider shade/ventilation.')
  if(insight.riskFlags.lowLight) actions.push('Low light detected — ensure crops receive sufficient sunlight.')
  actions.push(`Top recommended crop: ${topCrop}`)

  const confidence = totals[topCrop] ?? 0
  return { actions, confidence }
}

export { clamp, scoreRange, computeSuitabilityFromSensor, computeInsight, pickTopCrop, buildRecommendations, aggregateHistory }

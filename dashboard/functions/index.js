const functions = require('firebase-functions')
const admin = require('firebase-admin')

admin.initializeApp()
const db = admin.database()

// Helper: safe numeric
function toNumber(v){
  const n = Number(v)
  return Number.isFinite(n) ? n : null
}

// Append a snapshot of currentData into history/logs when currentData changes
// This function only creates a new log when relevant sensor fields actually change.
exports.appendLogFromCurrentData = functions.database
  .ref('/AgroSmart/currentData')
  .onWrite(async (change, context) => {
    const before = change.before.exists() ? change.before.val() : null
    const after = change.after.exists() ? change.after.val() : null

    // If data was deleted or missing after write, nothing to do
    if(!after) return null

    // Extract the sensor fields we care about
    const keys = ['temperature','humidity','soilMoisture','lightLevel','pumpStatus']

    // If before exists and all relevant fields are identical, do not create a log
    if(before){
      let changed = false
      for(const k of keys){
        const b = before[k]
        const a = after[k]
        // Normalize boolean/string/number comparisons conservatively
        if (typeof b === 'boolean' || typeof a === 'boolean'){
          if(Boolean(b) !== Boolean(a)){ changed = true; break }
        } else if (b != a) { // loose inequality to catch numeric-string differences
          changed = true; break
        }
      }
      if(!changed) return null
    }

    const ts = toNumber(after.timestamp) || Date.now()
    const payload = {
      temperature: after.temperature ?? after.Temperature ?? null,
      humidity: after.humidity ?? after.Humidity ?? null,
      soilMoisture: after.soilMoisture ?? after.SoilMoisture ?? after.soil ?? null,
      lightLevel: after.lightLevel ?? after.LightLevel ?? after.light ?? null,
      pumpStatus: (typeof after.pumpStatus !== 'undefined') ? Boolean(after.pumpStatus) : (typeof after.pump !== 'undefined' ? Boolean(after.pump) : false),
      timestamp: ts
    }

    const ref = db.ref('/AgroSmart/history/logs')
    await ref.push(payload)
    return null
  })

// Rule-based v1 scoring helpers and crop profiles
const PENALTY_FACTOR = 2.5 // tuning constant

function scoreRange(value, range){
  if(value === null || value === undefined) return 0
  const [min, max] = range
  if(value >= min && value <= max) return 100
  const dist = value < min ? (min - value) : (value - max)
  const score = Math.max(0, 100 - dist * PENALTY_FACTOR)
  return Math.round(score)
}

const CROP_PROFILES = {
  kidneybeans: { temp: [18,28], humidity: [45,75] },
  mungbean:    { temp: [22,32], humidity: [40,70] },
  chickpea:    { temp: [15,25], humidity: [20,55] }
}

// Compute suitability score for a single crop
function computeCropScore(cropProfile, sample){
  const temp = toNumber(sample.temperature)
  const hum = toNumber(sample.humidity)
  const soil = toNumber(sample.soilMoisture)
  const light = toNumber(sample.lightLevel)

  const tempScore = scoreRange(temp, cropProfile.temp) // 40%
  const humScore = scoreRange(hum, cropProfile.humidity) // 30%

  // soil heuristic: closeness to 2200 threshold (higher = drier)
  let soilScore = 50
  if(soil !== null){
    const ideal = 2200
    const diff = Math.abs(soil - ideal)
    // closer to ideal -> higher score. use arbitrary scale
    soilScore = Math.max(0, 100 - (diff / 20))
  }

  // light heuristic: normalize 0..5000 -> 0..100
  let lightScore = 50
  if(light !== null){
    const max = 5000
    lightScore = Math.min(100, Math.max(0, Math.round((light / max) * 100)))
  }

  const total = Math.round(
    tempScore * 0.4 + humScore * 0.3 + soilScore * 0.2 + lightScore * 0.1
  )

  return { tempScore, humScore, soilScore: Math.round(soilScore), lightScore, total }
}

// Compute insight and recommendations based on one log entry
exports.computeAIFromLog = functions.database
  .ref('/AgroSmart/history/logs/{logId}')
  .onCreate(async (snapshot, context) => {
    const log = snapshot.val()
    const ts = toNumber(log.timestamp) || Date.now()

    const temperature = toNumber(log.temperature)
    const humidity = toNumber(log.humidity)
    const soilMoisture = toNumber(log.soilMoisture)
    const lightLevel = toNumber(log.lightLevel)

    // compute flags
    const soilDry = (soilMoisture !== null) ? (soilMoisture > 2200) : false
    const heatRisk = (temperature !== null) ? (temperature > 35) : false
    const lowLight = (lightLevel !== null) ? (lightLevel < 500) : false

    // suitability per crop
    const suitability = {}
    const breakdown = {}
    Object.keys(CROP_PROFILES).forEach(crop => {
      const res = computeCropScore(CROP_PROFILES[crop], log)
      suitability[crop] = res.total
      breakdown[crop] = res
    })

    // choose top crop
    const sorted = Object.entries(suitability).sort((a,b)=>b[1]-a[1])
    const topCrop = sorted[0] ? sorted[0][0] : null
    const topScore = sorted[0] ? sorted[0][1] : 0

    // recommendations: simple rule-based actions
    const actions = []
    if(soilDry) actions.push('Irrigation recommended: soil moisture is low.')
    else actions.push('Soil moisture is within acceptable range.')
    if(heatRisk) actions.push('High temperature detected — consider shade/ventilation.')
    if(lowLight) actions.push('Low light detected — ensure crops receive sufficient sunlight.')
    actions.push(`Top recommended crop: ${topCrop} (score ${topScore})`)

    const irrigationAdvice = soilDry ? 'ON' : 'OFF'
    const soilStatus = soilDry ? 'Dry' : 'Optimal'

    const summary = soilDry ? 'Soil appears dry. Irrigation recommended.' : 'Soil moisture looks healthy. Continue monitoring.'

    const currentInsight = {
      timestamp: ts,
      soilStatus,
      irrigationAdvice,
      riskFlags: { heatRisk, lowLight, sensorStale: false },
      summary
    }

    const suitabilityOut = {
      ...suitability,
      basis: 'Rule-based v1',
      timestamp: ts
    }

    const recommendationsOut = {
      topCrop,
      actions,
      confidence: topScore,
      timestamp: ts
    }

    // write everything in a single update for efficiency
    const updates = {}
    updates['/AgroSmart/ai/currentInsight'] = currentInsight
    updates['/AgroSmart/ai/suitability'] = suitabilityOut
    updates['/AgroSmart/ai/recommendations'] = recommendationsOut
    updates[`/AgroSmart/ai/history/${context.params.logId}`] = {
      input: log,
      insight: currentInsight,
      suitability: suitabilityOut,
      recommendations: recommendationsOut
    }

    await db.ref().update(updates)
    return null
  })

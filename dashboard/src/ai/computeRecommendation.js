import { CROP_PATTERNS } from './cropPatterns'
import { normalizeFeature } from './normalize'
import { getMatchLevel } from './matchLevel'

// Compute a weighted Manhattan distance between input and crop patterns.
// Lower distance => better suitability.
export function computeRecommendation({ currentData = {}, farmProfile = {}, weather = {}, weights = null } = {}){
  // build input vector
  const input = {
    N: typeof farmProfile.N === 'number' ? farmProfile.N : null,
    P: typeof farmProfile.P === 'number' ? farmProfile.P : null,
    K: typeof farmProfile.K === 'number' ? farmProfile.K : null,
    temperature: typeof currentData.temperature === 'number' ? currentData.temperature : null,
    humidity: typeof currentData.humidity === 'number' ? currentData.humidity : null,
    ph: typeof farmProfile.ph === 'number' ? farmProfile.ph : null,
    rainfall: typeof weather.rainfall === 'number' ? weather.rainfall : null
  }

  const features = ["N", "P", "K", "temperature", "humidity", "ph", "rainfall"]
  const featureLabels = {
    N: "Nitrogen (N)",
    P: "Phosphorus (P)",
    K: "Potassium (K)",
    temperature: "Temperature",
    humidity: "Humidity",
    ph: "Soil pH",
    rainfall: "Rainfall"
  }

  const scores = {}
  const topList = []
  const diffsByCrop = {}

  Object.entries(CROP_PATTERNS).forEach(([crop, mean])=>{
    let distance = 0
    let used = 0
    const perDiffs = {}
    features.forEach((f)=>{
      const cur = normalizeFeature(f, input[f])
      const m = normalizeFeature(f, mean[f])
      if(typeof cur === 'number' && typeof m === 'number'){
        const diff = Math.abs(cur - m)
        distance += diff
        perDiffs[f] = Number(diff.toFixed(4))
        used += 1
      }
    })
    // if no usable features, set distance to Infinity
    if(used === 0) distance = Infinity
    scores[crop] = Number.isFinite(distance) ? Number(distance.toFixed(4)) : null
    topList.push({ crop, score: scores[crop] })
    diffsByCrop[crop] = perDiffs
  })

  const sorted = topList.filter(t=>t.score !== null).sort((a,b)=>a.score - b.score)
  const top3 = sorted.slice(0,3)
  const best = top3[0] ?? null
  const bestScore = best?.score ?? null
  const matchLevel = getMatchLevel(bestScore)
  const featureDiffs = best?.crop ? (diffsByCrop[best.crop] || {}) : {}
  const reasons = []
  if(best?.crop){
    const mean = CROP_PATTERNS[best.crop] || {}
    const diffs = features.map((f)=>{
      const diff = featureDiffs[f]
      const cur = input[f]
      const ideal = mean[f]
      if(typeof diff !== "number" || typeof cur !== "number" || typeof ideal !== "number"){
        return null
      }
      return { f, diff, cur, ideal }
    }).filter(Boolean).sort((a,b)=>b.diff - a.diff).slice(0,3)
    diffs.forEach(({ f, diff, cur, ideal })=>{
      let intensity = "close"
      if(diff >= 0.35) intensity = "very different"
      else if(diff >= 0.20) intensity = "different"
      else if(diff >= 0.10) intensity = "slightly different"
      reasons.push(`${featureLabels[f] || f} is ${intensity} (current: ${cur}, ideal: ${ideal}).`)
    })
  }

  return {
    bestCrop: best?.crop ?? null,
    bestScore,
    matchLevel,
    reasons,
    featureDiffs,
    scores,
    top3,
    inputUsed: input
  }
}

export default computeRecommendation

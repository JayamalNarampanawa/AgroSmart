import { HISTORICAL_MEANS_3 } from './historicalPatterns'

function clamp(n, min, max){
  if (typeof n !== 'number' || Number.isNaN(n)) return min
  return Math.max(min, Math.min(max, n))
}

// compute distance and diffs between current and mean, only for enabled features
function computeCropDistance(current = {}, mean = {}, enabledFeatures = []){
  const diffs = {}
  let distance = 0
  enabledFeatures.forEach(f=>{
    const cur = (typeof current[f] === 'number') ? current[f] : null
    const m = (typeof mean[f] === 'number') ? mean[f] : null
    const diff = (cur === null || m === null) ? null : Math.abs(cur - m)
    diffs[f] = diff
    if(diff !== null) distance += diff
  })
  return { distance, diffs }
}

// Convert distance to 0..100 suitability. Use exponential mapping for smoothness.
function distanceToSuitability(distance, method = 'exp', config = {}){
  if(distance === null || distance === undefined) return 0
  if(method === 'linear'){
    const factor = config.factor ?? 1.2
    return Math.round(clamp(100 - distance * factor, 0, 100))
  }
  // default exponential
  const scale = config.scale ?? 40
  return Math.round(100 * Math.exp(-distance / scale))
}

function selectEnabledFeatures(current){
  // temperature and humidity expected
  const features = ['temperature','humidity']
  if(typeof current.rainfall === 'number') features.push('rainfall')
  if(typeof current.ph === 'number') features.push('ph')
  return features
}

function computeSuitabilityForAllCrops(current){
  const enabled = selectEnabledFeatures(current)
  const missing = []
  if(!enabled.includes('rainfall')) missing.push('rainfall')
  if(!enabled.includes('ph')) missing.push('ph')

  const scores = {}
  const distances = {}
  const diffs = {}

  Object.entries(HISTORICAL_MEANS_3).forEach(([crop, mean])=>{
    const { distance, diffs: d } = computeCropDistance(current, mean, enabled)
    const score = distanceToSuitability(distance)
    scores[crop] = score
    distances[crop] = distance
    diffs[crop] = d
  })

  const topCrop = Object.entries(scores).sort((a,b)=>b[1]-a[1])[0]?.[0] ?? null

  return {
    scores,
    distances,
    diffs,
    topCrop,
    usedFeatures: enabled,
    missingFeatures: missing
  }
}

export { clamp, computeCropDistance, distanceToSuitability, computeSuitabilityForAllCrops }

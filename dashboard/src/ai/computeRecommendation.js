import { CROP_PATTERNS } from './cropPatterns'

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

  const defaultWeights = {
    N: 1, P: 1, K: 1,
    temperature: 1, humidity: 1, ph: 1, rainfall: 1
  }
  const w = { ...(defaultWeights), ...(weights || {}) }

  const scores = {}
  const topList = []

  Object.entries(CROP_PATTERNS).forEach(([crop, mean])=>{
    let distance = 0
    let used = 0
    Object.keys(defaultWeights).forEach(f=>{
      const cur = input[f]
      const m = mean[f]
      if(typeof cur === 'number' && typeof m === 'number'){
        distance += Math.abs(cur - m) * (w[f] ?? 1)
        used += 1
      }
    })
    // if no usable features, set distance to Infinity
    if(used === 0) distance = Infinity
    scores[crop] = Number.isFinite(distance) ? Number(distance) : null
    topList.push({ crop, score: scores[crop] })
  })

  const sorted = topList.filter(t=>t.score !== null).sort((a,b)=>a.score - b.score)
  const top3 = sorted.slice(0,3)
  const best = top3[0] ?? null

  return {
    bestCrop: best?.crop ?? null,
    bestScore: best?.score ?? null,
    scores,
    top3,
    inputUsed: input
  }
}

export default computeRecommendation

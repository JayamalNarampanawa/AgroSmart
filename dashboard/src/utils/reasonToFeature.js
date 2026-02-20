const FEATURE_KEYWORDS = [
  { key: 'temperature', patterns: ['temperature', 'temp', 'heat'] },
  { key: 'humidity', patterns: ['humidity', 'humid'] },
  { key: 'rainfall', patterns: ['rain', 'rainfall', 'precip'] },
  { key: 'ph', patterns: ['ph', 'pH'] },
  { key: 'soilMoisture', patterns: ['soil', 'moisture', 'wet'] },
  { key: 'lightLevel', patterns: ['light', 'lux', 'sun'] }
]

export function extractKeyFeatures(reasons) {
  if (!Array.isArray(reasons)) return []
  const picked = []
  const lowerReasons = reasons.filter(Boolean).map((r) => String(r).toLowerCase())
  for (const reason of lowerReasons) {
    for (const feat of FEATURE_KEYWORDS) {
      if (feat.patterns.some((p) => reason.includes(p.toLowerCase()))) {
        if (!picked.includes(feat.key)) picked.push(feat.key)
        if (picked.length >= 2) return picked
      }
    }
  }
  return picked
}

export default extractKeyFeatures

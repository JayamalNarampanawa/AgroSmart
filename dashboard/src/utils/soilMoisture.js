export const DEFAULT_SOIL_WET_MIN = 1200
export const DEFAULT_SOIL_DRY_MAX = 4095

export function clamp(n, min, max){
  if(typeof n !== 'number' || Number.isNaN(n)) return min
  return Math.min(max, Math.max(min, n))
}

export function getSoilMoistureConfig(settings){
  const rawWetMin = settings?.soilMoistureWetMin ?? settings?.wetMin ?? DEFAULT_SOIL_WET_MIN
  const rawDryMax = settings?.soilMoistureDryMax ?? settings?.dryMax ?? DEFAULT_SOIL_DRY_MAX
  const wetMin = typeof rawWetMin === 'number' ? rawWetMin : Number(rawWetMin)
  const dryMax = typeof rawDryMax === 'number' ? rawDryMax : Number(rawDryMax)
  if(!Number.isFinite(wetMin) || !Number.isFinite(dryMax) || dryMax <= wetMin){
    return { wetMin: DEFAULT_SOIL_WET_MIN, dryMax: DEFAULT_SOIL_DRY_MAX }
  }
  return { wetMin, dryMax }
}

export function soilWetnessPercent(raw, wetMin = DEFAULT_SOIL_WET_MIN, dryMax = DEFAULT_SOIL_DRY_MAX){
  if(raw === null || raw === undefined) return null
  const n = Number(raw)
  if(!Number.isFinite(n)) return null
  const pct = ((dryMax - n) / (dryMax - wetMin)) * 100
  return Math.round(clamp(pct, 0, 100))
}

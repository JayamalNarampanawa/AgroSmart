import { FEATURE_RANGES } from "./featureRanges"

export function normalizeFeature(name, value){
  const range = FEATURE_RANGES[name]
  if(!range || typeof value !== "number" || Number.isNaN(value)) return null

  const { min, max } = range
  if(max === min) return 0

  const v = Math.min(Math.max(value, min), max)
  return (v - min) / (max - min)
}

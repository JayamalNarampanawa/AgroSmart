export function getMatchLevel(score){
  if(score == null || !Number.isFinite(score)) return "Unknown"
  if(score < 0.35) return "Good"
  if(score < 0.70) return "Moderate"
  return "Poor"
}

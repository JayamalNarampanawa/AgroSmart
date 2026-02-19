export const calibration = {
  soil: {
    min: 0,
    max: 4095,
    dryMax: 1500,
    optimalMax: 2500,
    wetMin: 2500,
    pumpThreshold: 2200
  },
  light: {
    min: 0,
    max: 4095,
    invert: true
  },
  temp: {
    coolMax: 20,
    normalMax: 30,
    hotMin: 30
  },
  smoothing: {
    soilAlpha: 0.04,
    lightAlpha: 0.1,
    tempAlpha: 0.08,
    hudAlpha: 0.12
  }
}

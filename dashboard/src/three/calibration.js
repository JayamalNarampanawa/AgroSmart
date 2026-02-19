export const calibration = {
  soil: {
    min: 0,
    max: 4095,
    wet: 1369, // wetter sensor reading
    dry: 2606, // drier sensor reading
    hysteresis: 0.05,
    pumpThreshold: 2000,
  },
  light: {
    bright: 10,
    dark: 4095,
    hysteresis: 0.05,
  },
  temp: {
    coolMax: 20,
    normalMax: 30,
    hotMin: 30,
  },
  smoothing: {
    wetnessAlpha: 0.04,
    brightnessAlpha: 0.1,
    tempAlpha: 0.08,
    hudAlpha: 0.12,
  },
};

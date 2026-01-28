// Hardcoded crop pattern means (Kaggle dataset means) for three crops
export const CROP_PATTERNS = {
  chickpea: {
    N: 40.09,
    P: 67.79,
    K: 79.92,
    temperature: 18.87,
    humidity: 16.86,
    ph: 7.33,
    rainfall: 80.06
  },
  kidneybeans: {
    N: 20.75,
    P: 67.54,
    K: 20.05,
    temperature: 20.12,
    humidity: 21.61,
    ph: 5.75,
    rainfall: 105.92
  },
  mungbean: {
    N: 20.99,
    P: 47.28,
    K: 19.87,
    temperature: 28.53,
    humidity: 85.50,
    ph: 6.72,
    rainfall: 48.40
  }
}

export default CROP_PATTERNS

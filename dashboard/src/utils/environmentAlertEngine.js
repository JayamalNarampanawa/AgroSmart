export function evaluateAlerts({ live, cropIdeals, recommendedCrop }) {
  const alerts = [];

  if (!live) return alerts;

  const cropKey = recommendedCrop?.toLowerCase();
  const ideal = cropIdeals?.[cropKey];

  // ----- Temperature -----
  if (ideal?.temperature && live.temperature != null) {
    const diff = live.temperature - ideal.temperature;
    if (Math.abs(diff) > 3) {
      alerts.push({
        type: "temperature",
        severity: Math.abs(diff) > 6 ? "critical" : "warning",
        message: diff > 0 ? "Temperature too high" : "Temperature too low",
      });
    }
  }

  // ----- Humidity -----
  if (ideal?.humidity && live.humidity != null) {
    const diff = live.humidity - ideal.humidity;
    if (Math.abs(diff) > 8) {
      alerts.push({
        type: "humidity",
        severity: Math.abs(diff) > 15 ? "critical" : "warning",
        message: diff > 0 ? "Humidity too high" : "Humidity too low",
      });
    }
  }

  // ----- Soil Moisture (ADC logic) -----
  if (live.soilMoisture != null) {
    if (live.soilMoisture > 3300) {
      alerts.push({
        type: "soil",
        severity: "critical",
        message: "Soil too dry",
      });
    }
    if (live.soilMoisture < 1800) {
      alerts.push({
        type: "soil",
        severity: "warning",
        message: "Soil too wet",
      });
    }
  }

  // ----- Light Level -----
  if (live.lightLevel != null) {
    if (live.lightLevel < 1200) {
      alerts.push({
        type: "light",
        severity: "warning",
        message: "Light too low",
      });
    }
    if (live.lightLevel > 3800) {
      alerts.push({
        type: "light",
        severity: "warning",
        message: "Light too intense",
      });
    }
  }

  return alerts;
}

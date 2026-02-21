// Unified prototype cube with carved recess (tweakable cut area)
export const PROTOTYPE = {
  width: 0.44,   // 44cm
  depth: 0.57,   // 57cm
  height: 0.09,  // 9cm top level
  layer2Drop: 0.02,
  layer3Drop: 0.01,
  soilDrop: 0.02,
};

// Soil recess area on the top surface (tweakable rectangle)
// Origin at center; z+: front, z-: back. This assumes soil bed toward back/right.
export const CUT = {
  xMin: -0.12,
  xMax: 0.16,
  zMin: -0.28,
  zMax: 0.05,
};

export const POLE = {
  height: 0.16,
  radius: 0.01,
  mountLayer: 3, // place pole base on layer3 surface
  x: -0.16,
  z: 0.05,
};

export const COMPONENTS = [
  // Pole mounted (positions relative to world origin)
  { id: "dht11", label: "DHT11", position: { x: POLE.x, y: 0.14, z: POLE.z } },
  { id: "ldr", label: "LDR", position: { x: POLE.x, y: 0.10, z: POLE.z } },

  // Soil sensor in recess
  { id: "soil", label: "Soil Moisture", position: { x: -0.02, y: 0.045, z: -0.12 } },

  // Electronics cluster on grass region
  { id: "breadboard", label: "Breadboard", position: { x: 0.08, y: 0.065, z: 0.20 } },
  { id: "relay", label: "Relay", position: { x: 0.14, y: 0.065, z: 0.22 } },
  { id: "esp32", label: "ESP32", position: { x: 0.18, y: 0.065, z: 0.24 } },
];

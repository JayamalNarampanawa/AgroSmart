#include "DHT.h"

#define DHTPIN 4
#define DHTTYPE DHT11
#define SOIL_PIN 34
#define LDR_PIN 35
#define RELAY_PIN 26

DHT dht(DHTPIN, DHTTYPE);

void setup() {
  Serial.begin(115200);
  dht.begin();

  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, HIGH); // Pump OFF (active LOW relay)
}

void loop() {
  float temp = dht.readTemperature();
  float hum = dht.readHumidity();
  int soil = analogRead(SOIL_PIN);
  int light = analogRead(LDR_PIN);

  Serial.println("------ SENSOR DATA ------");
  Serial.print("Temperature: "); Serial.print(temp); Serial.println(" °C");
  Serial.print("Humidity: "); Serial.print(hum); Serial.println(" %");
  Serial.print("Soil Moisture: "); Serial.println(soil);
  Serial.print("Light Level: "); Serial.println(light);

  // Simple irrigation rule
  if (soil > 2500) {  // Dry soil
    digitalWrite(RELAY_PIN, LOW);  // Pump ON
    Serial.println("Irrigation: ON");
  } else {
    digitalWrite(RELAY_PIN, HIGH); // Pump OFF
    Serial.println("Irrigation: OFF");
  }

  Serial.println("--------------------------\n");
  delay(3000);
}

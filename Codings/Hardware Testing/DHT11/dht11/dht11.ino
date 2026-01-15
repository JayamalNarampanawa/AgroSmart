#define SOIL_PIN 34

void setup() {
  Serial.begin(115200);
}

void loop() {
  int soil = analogRead(SOIL_PIN);
  Serial.print("Soil Moisture Value: ");
  Serial.println(soil);
  delay(1000);
}

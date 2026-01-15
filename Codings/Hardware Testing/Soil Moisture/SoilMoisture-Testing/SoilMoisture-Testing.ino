#define LDR_PIN 35

void setup() {
  Serial.begin(115200);
}

void loop() {
  int light = analogRead(LDR_PIN);
  Serial.print("Light Intensity: ");
  Serial.println(light);
  delay(1000);
}

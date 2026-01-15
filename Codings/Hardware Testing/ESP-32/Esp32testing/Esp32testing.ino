void setup() {
  Serial.begin(115200);
  Serial.println("ESP32 Ready");
}

void loop() {
  Serial.println("Running");
  delay(1000);
}

#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include "DHT.h"

// -------- WiFi --------
#define WIFI_SSID "ssis-ESP1"
#define WIFI_PASSWORD "12345678"

// -------- Firebase --------
#define API_KEY "AIzaSyDTFHx8jKrkeXCwtGeBDQV29phYd2e_UdM"
#define DATABASE_URL "https://agro-smart-2026-default-rtdb.firebaseio.com/"

FirebaseData fbdo;
FirebaseAuth auth;          // Empty auth for public access
FirebaseConfig config;      // Config with API key & DB URL

// -------- Sensors --------
#define DHTPIN 4
#define DHTTYPE DHT11
#define SOIL_PIN 34
#define LDR_PIN 35
#define RELAY_PIN 26

DHT dht(DHTPIN, DHTTYPE);

// -------- Soil Reading Function --------
int readSoil() {
  long sum = 0;
  for (int i = 0; i < 10; i++) {
    sum += analogRead(SOIL_PIN);
    delay(10);
  }
  return sum / 10;
}

// -------- SETUP --------
void setup() {
  Serial.begin(115200);
  dht.begin();
  analogSetAttenuation(ADC_11db);

  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, HIGH);  // Pump OFF

  // -------- Connect WiFi --------
  Serial.print("Connecting to WiFi");
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(500);
  }
  Serial.println("\nWiFi Connected!");

  // -------- Firebase Config --------
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;

  // Test mode (no auth)
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  Serial.println("Firebase Ready!");
}

// -------- LOOP (THIS FIXES YOUR ERROR) --------
void loop() {

  float temperature = dht.readTemperature();
  float humidity = dht.readHumidity();
  int soil = readSoil();
  int light = analogRead(LDR_PIN);

  if (isnan(temperature) || isnan(humidity)) {
    Serial.println("DHT Read Failed!");
    delay(2000);
    return;
  }

  Serial.println("----- Sensor Data -----");
  Serial.print("Temp: "); Serial.println(temperature);
  Serial.print("Humidity: "); Serial.println(humidity);
  Serial.print("Soil: "); Serial.println(soil);
  Serial.print("Light: "); Serial.println(light);

  // -------- Firebase Upload --------
  if (Firebase.ready()) {
    Firebase.RTDB.setFloat(&fbdo, "/AgriBot/temperature", temperature);
    Firebase.RTDB.setFloat(&fbdo, "/AgriBot/humidity", humidity);
    Firebase.RTDB.setInt(&fbdo, "/AgriBot/soil", soil);
    Firebase.RTDB.setInt(&fbdo, "/AgriBot/light", light);
  }

  delay(5000);  // Upload every 5 seconds
}

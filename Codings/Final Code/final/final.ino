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
FirebaseAuth auth;
FirebaseConfig config;

// -------- Sensors --------
#define DHTPIN 4
#define DHTTYPE DHT11
#define SOIL_PIN 34
#define LDR_PIN 35
#define RELAY_PIN 26

DHT dht(DHTPIN, DHTTYPE);

// -------- Read Soil Moisture (average) --------
int readSoil() {
  long sum = 0;
  for (int i = 0; i < 10; i++) {
    sum += analogRead(SOIL_PIN);
    delay(10);
  }
  return sum / 10;
}

void setup() {
  Serial.begin(115200);
  dht.begin();
  analogSetAttenuation(ADC_11db);

  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, HIGH);   // Pump OFF initially (relay active LOW)

  // -------- WiFi --------
  Serial.print("Connecting to WiFi");
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(500);
  }
  Serial.println("\nWiFi Connected!");

  // -------- Firebase --------
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;

  if (Firebase.signUp(&config, &auth, "", "")) {
    Serial.println("Firebase Auth OK");
  } else {
    Serial.printf("Auth failed: %s\n",
      config.signer.signupError.message.c_str());
  }

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
}

void loop() {

  float temperature = dht.readTemperature();
  float humidity = dht.readHumidity();
  int soil = readSoil();
  int light = analogRead(LDR_PIN);

  Serial.println("------ SENSOR DATA ------");
  Serial.print("Temperature: "); Serial.println(temperature);
  Serial.print("Humidity: "); Serial.println(humidity);
  Serial.print("Soil Moisture: "); Serial.println(soil);
  Serial.print("Light Level: "); Serial.println(light);

  // -------- CORRECT IRRIGATION LOGIC --------
  // LOW value = WET
  // HIGH value = DRY

  String irrigationStatus;

  if (soil > 2200) {          // DRY soil → Pump ON
    digitalWrite(RELAY_PIN, LOW);
    irrigationStatus = "ON";
  } else {                    // WET soil → Pump OFF
    digitalWrite(RELAY_PIN, HIGH);
    irrigationStatus = "OFF";
  }

  // -------- Firebase Upload --------
  Firebase.RTDB.setFloat(&fbdo, "/AgroSmart/Temperature", temperature);
  Firebase.RTDB.setFloat(&fbdo, "/AgroSmart/Humidity", humidity);
  Firebase.RTDB.setInt(&fbdo, "/AgroSmart/SoilMoisture", soil);
  Firebase.RTDB.setInt(&fbdo, "/AgroSmart/LightLevel", light);
  Firebase.RTDB.setString(&fbdo, "/AgroSmart/Irrigation", irrigationStatus);

  Serial.print("Irrigation: ");
  Serial.println(irrigationStatus);
  Serial.println("--------------------------\n");

  delay(5000);
}

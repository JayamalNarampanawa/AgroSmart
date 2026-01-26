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
  digitalWrite(RELAY_PIN, HIGH);

  // WiFi
  Serial.print("Connecting to WiFi");
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(500);
  }
 Serial.println("\nWiFi Connected!");

config.api_key = API_KEY;
config.database_url = DATABASE_URL;

if (Firebase.signUp(&config, &auth, "", "")) {
  Serial.println("Firebase Auth OK");
} else {
  Serial.printf("Auth failed: %s\n", config.signer.signupError.message.c_str());
}

Firebase.begin(&config, &auth);
Firebase.reconnectWiFi(true);

}

// 🔥 REQUIRED FUNCTION (THIS FIXES YOUR ERROR)
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

  String irrigationStatus;
  if (soil > 2200) {
    digitalWrite(RELAY_PIN, LOW);
    irrigationStatus = "ON";
  } else {
    digitalWrite(RELAY_PIN, HIGH);
    irrigationStatus = "OFF";
  }

  if (Firebase.RTDB.setFloat(&fbdo, "/AgroSmart/Temperature", temperature))
    Serial.println("Temp sent");
  else
    Serial.println(fbdo.errorReason());

  if (Firebase.RTDB.setFloat(&fbdo, "/AgroSmart/Humidity", humidity))
    Serial.println("Humidity sent");
  else
    Serial.println(fbdo.errorReason());

  if (Firebase.RTDB.setInt(&fbdo, "/AgroSmart/SoilMoisture", soil))
    Serial.println("Soil sent");
  else
    Serial.println(fbdo.errorReason());

  if (Firebase.RTDB.setInt(&fbdo, "/AgroSmart/LightLevel", light))
    Serial.println("Light sent");
  else
    Serial.println(fbdo.errorReason());

  if (Firebase.RTDB.setString(&fbdo, "/AgroSmart/Irrigation", irrigationStatus))
    Serial.println("Irrigation sent");
  else
    Serial.println(fbdo.errorReason());

  Serial.println("--------------------------\n");

  delay(5000);
}

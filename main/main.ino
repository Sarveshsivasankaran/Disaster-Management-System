#include <Wire.h>
#include <MPU6050_light.h>
#include <Adafruit_BMP280.h>
#include <ESP8266WiFi.h>
#include <ESP8266HTTPClient.h>
#include <WiFiClientSecureBearSSL.h>
#include <ArduinoJson.h>

// ================== CONFIG ==================
const char* WIFI_SSID = "Xx";
const char* WIFI_PASS = "sarvesh@2643";

const char* SUPABASE_URL =
  "https://nqipgzknhlfsrezssoyr.supabase.co/rest/v1/buoys";

const char* SUPABASE_KEY ="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5xaXBnemtuaGxmc3JlenNzb3lyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgzNzQ4ODYsImV4cCI6MjA3Mzk1MDg4Nn0.M1xc6HtScdDjemguonpPgmo8EF0A93OoHvy4LACO24E";  // 🔥 REQUIRED

const char* BUOY_ID = "BOUY12";
const char* LOCATION = "Chennai Harbor";

// Pins
#define TRIG_PIN D6
#define ECHO_PIN D7
#define BAT_PIN  A0

// Voltage divider
const float VOLTAGE_DIVIDER = 0.203;

// ================== OBJECTS ==================
MPU6050 mpu(Wire);
Adafruit_BMP280 bmp;
bool bmp_ok = false;

// ================== UTILS ==================
float readBattery() {
  int raw = analogRead(BAT_PIN);
  float v = (raw / 1023.0) * 3.3;
  return v / VOLTAGE_DIVIDER;
}

float readUltrasonic() {
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);

  long duration = pulseIn(ECHO_PIN, HIGH, 30000);
  if (!duration) return -1;
  return (duration * 0.0343) / 2.0;
}

// ================== SUPABASE ==================
bool sendToSupabase(float waterLevel, float waveHeight, float temp, float battery) {
  if (WiFi.status() != WL_CONNECTED) return false;

  BearSSL::WiFiClientSecure client;
  client.setInsecure();

  HTTPClient http;
  http.begin(client, SUPABASE_URL);

  http.addHeader("Content-Type", "application/json");
  http.addHeader("apikey", SUPABASE_KEY);
  http.addHeader("Authorization", String("Bearer ") + SUPABASE_KEY);
  http.addHeader("Prefer", "resolution=merge-duplicates");

  StaticJsonDocument<512> doc;
  doc["id"] = BUOY_ID;
  doc["location"] = LOCATION;
  doc["latitude"] = 13.0097429;
  doc["longitude"] = 80.0050476;
  doc["water_level"] = waterLevel;
  doc["wave_height"] = waveHeight;
  doc["temperature"] = temp;
  doc["status"] = "active";
  doc["battery_level"] = (int)(battery * 100 / 4.2);
  doc["signal_strength"] = WiFi.RSSI();

  String payload;
  serializeJson(doc, payload);

  int code = http.POST(payload);
  Serial.println(code);

  http.end();
  return (code >= 200 && code < 300);
}

// ================== SETUP ==================
void setup() {
  Serial.begin(115200);

  Wire.begin(D2, D1);

  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);

  mpu.begin();
  bmp_ok = bmp.begin(0x76);

  WiFi.begin(WIFI_SSID, WIFI_PASS);
  Serial.print("Connecting WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi Connected");
}

// ================== LOOP ==================
void loop() {
  mpu.update();

  float accX = mpu.getAccX();
  float accY = mpu.getAccY();
  float accZ = mpu.getAccZ();
  float waveHeight = sqrt(accX * accX + accY * accY + accZ * accZ);

  float waterLevel = readUltrasonic();
  float temperature = bmp_ok ? bmp.readTemperature() : 0;
  float battery = readBattery();

  bool ok = sendToSupabase(
    waterLevel,
    waveHeight,
    temperature,
    battery
  );

  Serial.println(ok ? "UPLOAD OK" : "UPLOAD FAILED");

  delay(5000);
}
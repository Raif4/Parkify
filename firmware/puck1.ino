#include <ESP8266WiFi.h>
#include <espnow.h>
#include <Wire.h>
#include <math.h>
extern "C" {
  #include "user_interface.h"
}

// ===== PUCK 1 (QMC5883P at 0x2C) =====
const int SLOT_ID = 1;
uint8_t GATEWAY_MAC[] = {0xD8, 0xBF, 0xC0, 0xE2, 0xB9, 0xE2};
#define WIFI_CH 6
#define MAG 0x2C
// =====================================

// Change thresholds in microtesla (NOT raw counts). Tune with the real car.
float T_ON = 8.0f;
float T_OFF = 4.0f;

const uint32_t ON_MS = 60;
const uint32_t OFF_MS = 400;

float baselineMag = 0;
float smoothMag = 0;
float gDelta = 0;

bool occupied = false;
bool sensorOk = false;

uint32_t candidateMs = 0;
uint32_t lastDrift = 0;
uint32_t lastPrint = 0;
uint32_t lastSend = 0;
uint32_t lastCal = 0;
volatile bool recalFlag = false;

struct __attribute__((packed)) Pkt { uint8_t slot; uint8_t taken; };

// ---------- ESP-NOW ----------

void sendState() {
  Pkt k = { (uint8_t)SLOT_ID, (uint8_t)occupied };
  esp_now_send(GATEWAY_MAC, (uint8_t*)&k, sizeof(k));
}

// command from the gateway: data[0] = 0xCA, data[1] = slot (0 = all pucks)
void onCmd(uint8_t* mac, uint8_t* data, uint8_t len) {
  if (len < 2 || data[0] != 0xCA) return;
  uint8_t s = data[1];
  if ((s == 0 || s == SLOT_ID) && millis() - lastCal > 3000) recalFlag = true;
}

// ---------- I2C HELPERS ----------

bool writeReg(uint8_t reg, uint8_t val) {
  Wire.beginTransmission(MAG);
  Wire.write(reg);
  Wire.write(val);
  return Wire.endTransmission() == 0;
}

bool readRegs(uint8_t reg, uint8_t* buf, uint8_t n) {
  Wire.beginTransmission(MAG);
  Wire.write(reg);
  if (Wire.endTransmission(false) != 0) return false;
  uint8_t received = Wire.requestFrom((uint8_t)MAG, n);
  if (received != n) {
    while (Wire.available()) Wire.read();
    return false;
  }
  for (uint8_t i = 0; i < n; i++) buf[i] = Wire.read();
  return true;
}

// ---------- SENSOR ----------

bool initSensor() {
  uint8_t id = 0;
  if (readRegs(0x00, &id, 1)) {
    Serial.printf("Chip ID: 0x%02X (QMC5883P expects 0x80)\n", id);
  }
  if (!writeReg(0x0B, 0x08)) return false;   // 8 gauss range, set/reset on
  if (!writeReg(0x0A, 0xCF)) return false;   // continuous mode, 200 Hz
  delay(100);
  Serial.println("Initialized QMC5883P at 0x2C.");
  return true;
}

bool readField(float &x, float &y, float &z) {
  uint8_t status;
  uint8_t b[6];

  if (!readRegs(0x09, &status, 1)) return false;
  if (!(status & 0x01)) return false;            // data not ready yet
  if (!readRegs(0x01, b, 6)) return false;       // X, Y, Z little-endian

  int16_t rx = (int16_t)(((uint16_t)b[1] << 8) | b[0]);
  int16_t ry = (int16_t)(((uint16_t)b[3] << 8) | b[2]);
  int16_t rz = (int16_t)(((uint16_t)b[5] << 8) | b[4]);

  const float UT_PER_COUNT = 100.0f / 3750.0f;   // 8 gauss range
  x = rx * UT_PER_COUNT;
  y = ry * UT_PER_COUNT;
  z = rz * UT_PER_COUNT;
  return true;
}

// ---------- CALIBRATION ----------

void calibrate() {
  lastCal = millis();
  Serial.println();
  Serial.println("Calibrating baseline.");
  Serial.println("Keep sensor still and slot empty.");

  float sumMag = 0;
  int n = 0;
  uint32_t start = millis();

  while (n < 100 && millis() - start < 7000) {
    float x, y, z;
    if (readField(x, y, z)) {
      sumMag += sqrtf(x*x + y*y + z*z);
      n++;
    }
    delay(10);
    yield();
  }

  if (n < 20) {
    Serial.println("Calibration failed: too few readings.");
    sensorOk = false;
    return;
  }

  baselineMag = sumMag / n;
  smoothMag = baselineMag;
  gDelta = 0;

  occupied = false;
  candidateMs = 0;
  lastDrift = millis();
  sensorOk = true;

  Serial.printf("Baseline magnitude: %.2f uT (%d samples)\n", baselineMag, n);
  Serial.println("Calibration complete.");
  sendState();
}

// ---------- SETUP ----------

void setup() {
  Serial.begin(115200);

  Wire.begin(4, 5);            // D2 = SDA, D1 = SCL
  Wire.setClock(400000);
  delay(300);

  Serial.println();
  Serial.printf("Parkify puck, slot %d\n", SLOT_ID);

  sensorOk = initSensor();
  if (!sensorOk) Serial.println("Sensor initialization failed. Check wiring.");

  WiFi.mode(WIFI_STA);
  wifi_set_channel(WIFI_CH);
  if (esp_now_init() != 0) Serial.println("ESP-NOW failed");
  esp_now_set_self_role(ESP_NOW_ROLE_COMBO);
  esp_now_add_peer(GATEWAY_MAC, ESP_NOW_ROLE_COMBO, WIFI_CH, NULL, 0);
  esp_now_register_recv_cb(onCmd);

  delay(1500);                 // keep magnets and the car away
  if (sensorOk) calibrate();

  Serial.println("Type c in Serial Monitor to recalibrate.");
}

// ---------- MAIN LOOP ----------

void loop() {
  while (Serial.available()) {
    char c = Serial.read();
    if (c == 'c' || c == 'C') recalFlag = true;
  }

  if (recalFlag) {
    recalFlag = false;
    if (sensorOk) calibrate();
  }

  if (!sensorOk) {
    delay(100);
    return;
  }

  float x, y, z;
  if (!readField(x, y, z)) {
    delay(1);
    return;
  }

  float mag = sqrtf(x*x + y*y + z*z);
  smoothMag += 0.5f * (mag - smoothMag);          // fast filter
  gDelta = fabsf(smoothMag - baselineMag);

  uint32_t now = millis();

  if (!occupied) {
    if (gDelta > T_ON) {
      if (candidateMs == 0) candidateMs = now;
      if (now - candidateMs >= ON_MS) {
        occupied = true;
        candidateMs = 0;
        Serial.println(">>> OCCUPIED");
        sendState();
      }
    } else {
      candidateMs = 0;
    }
  } else {
    if (gDelta < T_OFF) {
      if (candidateMs == 0) candidateMs = now;
      if (now - candidateMs >= OFF_MS) {
        occupied = false;
        candidateMs = 0;
        Serial.println(">>> FREE");
        sendState();
      }
    } else {
      candidateMs = 0;
    }
  }

  // very slow baseline drift correction while free
  if (!occupied && gDelta < T_OFF && now - lastDrift >= 500) {
    lastDrift = now;
    baselineMag += 0.002f * (smoothMag - baselineMag);
  }

  // heartbeat so the gateway always has the latest state
  if (now - lastSend >= 2000) {
    lastSend = now;
    sendState();
  }

  if (now - lastPrint >= 1000) {
    lastPrint = now;
    Serial.printf("B=%.2f uT  change=%.2f uT  %s\n",
                  smoothMag, gDelta, occupied ? "OCCUPIED" : "FREE");
  }
}

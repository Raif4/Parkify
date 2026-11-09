#include <ESP8266WiFi.h>
#include <ESP8266WebServer.h>
#include <espnow.h>
#include <MD_Parola.h>
#include <MD_MAX72xx.h>
#include <SPI.h>

// ---------- EDIT THESE ----------
const char* WIFI_SSID = "YOUR_WIFI_NAME";
const char* WIFI_PASS = "YOUR_PASSWORD";
IPAddress GW_IP(192, 168, 1, 50);     // gateway's fixed address
IPAddress ROUTER_IP(192, 168, 1, 1);  // your router
IPAddress SUBNET(255, 255, 255, 0);
#define DEMO_MODE false  // true = fake slot changes on the sign
#define FLIP true        // set false if the picture is mirrored
// --------------------------------

#define HW_TYPE MD_MAX72XX::FC16_HW
#define DEVICES 4
#define CS_PIN D2

MD_Parola p(HW_TYPE, CS_PIN, DEVICES);
MD_MAX72XX* mx;
ESP8266WebServer server(80);

const uint8_t P_G[5]    = {0x7F, 0x09, 0x09, 0x09, 0x06};
const uint8_t DIG_1[3]  = {0x24, 0x3E, 0x20};
const uint8_t DIG_2[3]  = {0x3A, 0x2A, 0x2E};
const uint8_t TICK[7]   = {0x08, 0x10, 0x60, 0x30, 0x0C, 0x06, 0x03};
const uint8_t CROSS[7]  = {0x41, 0x22, 0x14, 0x08, 0x14, 0x22, 0x41};

volatile bool taken[2] = {false, false};
bool blinkOn = true, bannerMode = false;
unsigned long lastBlink = 0, modeStart = 0, lastDemo = 0;
uint8_t demoStep = 0;
char bannerText[24];

struct __attribute__((packed)) Pkt { uint8_t slot; uint8_t taken; };
struct __attribute__((packed)) Cmd { uint8_t magic; uint8_t slot; };
uint8_t BCAST[] = {0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF};

void onRecv(uint8_t* mac, uint8_t* data, uint8_t len) {
  if (len < sizeof(Pkt)) return;
  Pkt* k = (Pkt*)data;
  if (k->slot == 1 || k->slot == 2) taken[k->slot - 1] = k->taken;
}

void col(uint8_t x, uint8_t v) { mx->setColumn(FLIP ? 31 - x : x, v); }
void put(uint8_t x, const uint8_t* g, uint8_t w) {
  for (uint8_t i = 0; i < w; i++) col(x + i, g[i]);
}

void drawIcons(bool on) {
  mx->control(MD_MAX72XX::UPDATE, MD_MAX72XX::OFF);
  mx->clear();
  put(0, P_G, 5);
  put(8, DIG_1, 3);
  put(21, DIG_2, 3);
  if (taken[0]) put(12, CROSS, 7); else if (on) put(12, TICK, 7);
  if (taken[1]) put(25, CROSS, 7); else if (on) put(25, TICK, 7);
  mx->control(MD_MAX72XX::UPDATE, MD_MAX72XX::ON);
  mx->update();
}

void startBanner() {
  if (taken[0] && taken[1]) strcpy(bannerText, "FULL");
  else if (!taken[0] && !taken[1]) strcpy(bannerText, "2 SLOTS FREE");
  else if (!taken[0]) strcpy(bannerText, "SLOT 1 FREE");
  else strcpy(bannerText, "SLOT 2 FREE");
  bannerMode = true;
  p.displayClear();
  p.displayText(bannerText, PA_LEFT, 40, 0, PA_SCROLL_LEFT, PA_SCROLL_LEFT);
}

void handleStatus() {
  String j = "{\"slots\":[{\"id\":1,\"taken\":";
  j += taken[0] ? "true" : "false";
  j += "},{\"id\":2,\"taken\":";
  j += taken[1] ? "true" : "false";
  j += "}],\"free\":";
  j += String((!taken[0]) + (!taken[1]));
  j += "}";
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.send(200, "application/json", j);
}

// /recalibrate?slot=1 or 2, or slot=0 for both pucks
void handleRecal() {
  int slot = server.arg("slot").toInt();
  if (slot < 0 || slot > 2) {
    server.send(400, "text/plain", "bad slot");
    return;
  }
  Cmd c = { 0xCA, (uint8_t)slot };
  for (int i = 0; i < 3; i++) {
    esp_now_send(BCAST, (uint8_t*)&c, sizeof(c));
    delay(40);
  }
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.send(200, "application/json", "{\"ok\":true}");
}

void setup() {
  Serial.begin(115200);
  p.begin();
  mx = p.getGraphicObject();
  p.setIntensity(3);
  p.displayClear();
  drawIcons(true);

  WiFi.mode(WIFI_STA);
  WiFi.setSleepMode(WIFI_NONE_SLEEP);
  WiFi.config(GW_IP, ROUTER_IP, SUBNET);
  WiFi.begin(WIFI_SSID, WIFI_PASS);
  unsigned long t = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - t < 20000) delay(250);

  Serial.println();
  Serial.print("MAC: ");     Serial.println(WiFi.macAddress());
  Serial.print("Channel: "); Serial.println(WiFi.channel());
  Serial.print("IP: ");      Serial.println(WiFi.localIP());

  if (esp_now_init() != 0) Serial.println("ESP-NOW failed");
  else {
    esp_now_set_self_role(ESP_NOW_ROLE_COMBO);
    esp_now_register_recv_cb(onRecv);
    esp_now_add_peer(BCAST, ESP_NOW_ROLE_COMBO, 0, NULL, 0);
  }
  server.on("/status", handleStatus);
  server.on("/recalibrate", handleRecal);
  server.begin();
  modeStart = millis();
}

void loop() {
  server.handleClient();
  unsigned long now = millis();

  if (DEMO_MODE && now - lastDemo > 4000) {
    lastDemo = now;
    demoStep = (demoStep + 1) % 4;
    taken[0] = demoStep & 1;
    taken[1] = demoStep & 2;
  }

  if (!bannerMode) {
    if (now - lastBlink >= 500) {
      lastBlink = now;
      blinkOn = !blinkOn;
      drawIcons(blinkOn);
    }
    if (now - modeStart >= 12000) startBanner();
  } else if (p.displayAnimate()) {
    p.displayClear();
    bannerMode = false;
    modeStart = now;
    drawIcons(true);
  }
}

# Parkify: Live Parking Slot Detection

**Maker Challenge 2026 entry, CFAL Makers' Fete**
**Team Axiom Labs:** Raif, Anwesh.

> Know whether a parking slot is free before you reach it: on the entrance sign and on your phone.

---

## 1. Project title

**Parkify: a magnetic parking slot sensor system with a live entrance sign and a phone app**

## 2. Brief description / objective

**The problem.** In a busy mall, drivers circle the basement hunting for a free slot, and they have no way of knowing from home whether there is any parking at all. Malls often solve this by paying attendants to guide cars.

**What Parkify does.** A small sensor "puck" sits in every parking slot. It measures the magnetic field around it. A parked vehicle (steel body and engine) disturbs that field, and the puck detects the change. Each puck sends its state wirelessly to a gateway, which:

- drives an LED sign at the mall entrance (a tick for a free slot, a cross for a taken one),
- serves live slot data over the local network to the Parkify phone app.

This prototype has two slots and is built to scale to more.

## 3. Materials and components

| Part | Qty | Used for |
|---|---|---|
| ESP8266 NodeMCU | 3 | 1 per puck (x2); 1 is the gateway, which also drives the LED matrix sign |
| Magnetometer module, QMC5883P (I2C 0x2C) | 1 | Puck 1 sensor |
| Magnetometer module, QMC5883L (I2C 0x0D) | 1 | Puck 2 sensor |
| MAX7219 4-in-1 LED matrix (FC-16, 32x8, red) | 1 | Entrance sign |
| Power banks | 3 | Power for each puck and the gateway |
| Old Wi-Fi router (no internet needed) | 1 | Local network |
| Android phone | 1 | Runs the Parkify app |
| Jumper wires | - | Wiring |
| 3D-printed puck enclosures | 2 | Housing, designed in OpenSCAD |
| Tray and ramp board, entrance wall board, printed sticker vinyl | - | Demo set |
| Toy RC car with a magnet underneath | 1 | Demo vehicle |

**Tools and software:** 3D printer, craft knife and saw, Arduino IDE, OpenSCAD, Flutter, a laptop.

## 4. Step-by-step build

**Step 1: Sensor and microcontroller.** Wire each magnetometer to an ESP8266.

| Sensor pin | NodeMCU pin |
|---|---|
| VCC | 3V3 |
| GND | GND |
| SDA | D2 |
| SCL | D1 |

**Step 2: Identify the chips.** The two modules look identical but contain different chips. An I2C scan found address `0x2C` on one and `0x0D` on the other, so each puck has its own firmware setup.

**Step 3: Puck enclosures.** The puck body was designed in OpenSCAD, with a lid carrying the P logo and the name Parkify, and a side hole for the power cable. Printed on a 3D printer.

**Step 4: Detection firmware.** On power-up each puck measures the magnetic field of the empty slot for a few seconds (the baseline), then watches for a change. Details in section 5.

**Step 5: Wireless link.** Pucks send their state to the gateway using ESP-NOW, a direct radio link between ESP boards that needs no Wi-Fi connection at the slot.

**Step 6: Gateway.** A third ESP8266 receives the pucks' messages and joins the router with a fixed IP address. It serves a small web API (see section 5).

**Step 7: Entrance sign.** The LED matrix connects to the gateway.

| Matrix pin | NodeMCU pin |
|---|---|
| VCC | VIN |
| GND | GND |
| DIN | D7 |
| CLK | D5 |
| CS | D2 |

It shows `P`, the slot numbers, and a blinking tick for free or a solid cross for taken. A short scrolling message (for example `SLOT 2 FREE` or `FULL`) plays periodically.

**Step 8: Phone app.** A Flutter app polls the gateway and shows each slot live, with a Recalibrate button.

**Step 9: Demo set.** A tray with a divider for two slots, a ramp, and a removable entrance wall that carries the LED sign. The wall stands between two rail strips, so it can be lifted out. The toy car carries a magnet underneath and is placed over each puck by hand.

## 5. Working explanation and code

### System overview

The gateway ESP8266 does three jobs: it receives the pucks' ESP-NOW messages, drives the LED matrix entrance sign, and joins the local Wi-Fi router so phones can read the slot data. The router needs no internet connection.


### **1️⃣ Power Plan (FINAL)**



| Voltage                         | Connected Components                                       |

| ------------------------------- | ---------------------------------------------------------- |

| \*\*ESP32 3.3V pin\*\*              | DHT11, Capacitive Soil Moisture, LDR (via voltage divider) |

| \*\*External 5V supply\*\*          | Ultrasonic Sensor (HC-SR04), Relay Module                  |

| \*\*External 5V supply for pump\*\* | Water pump DC                                              |

| \*\*Common Ground (GND)\*\*         | ESP32 GND + all sensor GNDs + relay GND + pump GND         |





⚠️ All grounds must be connected together — this is critical.



#### **2️⃣ ESP32 Pin Assignment (FINAL)**



| Component                    | ESP32 Pin | Notes                                         |

| ---------------------------- | --------- | --------------------------------------------- |

| DHT11 DATA                   | GPIO 4    | 3.3V VCC, 10kΩ pull-up resistor               |

| Capacitive Soil Moisture AO  | GPIO 34   | Analog input                                  |

| LDR Output (Voltage Divider) | GPIO 35   | Analog input                                  |

| Ultrasonic TRIG              | GPIO 5    | Digital output                                |

| Ultrasonic ECHO              | GPIO 18   | Digital input via voltage divider (1kΩ + 2kΩ) |

| Relay IN                     | GPIO 26   | Digital output, controls pump                 |



#### **3️⃣ Individual Sensor \& Module Wiring**



###### 🔹 **DHT11 (Temperature \& Humidity)**



VCC → ESP32 3.3V

DATA → GPIO 4

GND → Common GND

Pull-up resistor 10kΩ between VCC and DATA





###### **🔹 Capacitive Soil Moisture Sensor**



VCC → ESP32 3.3V

AO → GPIO 34

GND → Common GND



###### **🔹 LDR (Light Intensity)**



3.3V → LDR → GPIO 35 → 10kΩ resistor → GND



###### **🔹 Ultrasonic Sensor HC-SR04**



VCC → External 5V

TRIG → GPIO 5

ECHO → GPIO 18 (via 1kΩ + 2kΩ voltage divider)

GND → Common GND



###### **🔹 Relay Module \& Pump**



VCC → External 5V

IN → GPIO 26

GND → Common GND



Relay COM → + Pump

Relay NO  → + of External 5V supply for pump

Pump -    → GND of external supply





#### 4️⃣ Full System Wiring (Text-Based Diagram)



&nbsp;                ┌───────────┐

&nbsp;             │  ESP32    │

&nbsp;             │           │

GPIO4   <─────┤ DHT11 DATA

3.3V   ──────>│ VCC

GND    ──────>│ GND

&nbsp;             └───────────┘



GPIO34  <───── AO Soil Moisture

3.3V   ──────> VCC

GND    ──────> GND



GPIO35  <───── Voltage divider output (LDR)

3.3V   ──────> LDR → 10kΩ → GND



GPIO5   ──────> TRIG Ultrasonic

GPIO18 <───── ECHO Ultrasonic (via 1kΩ + 2kΩ divider)

5V     ──────> VCC Ultrasonic

GND    ──────> GND



GPIO26 ──────> Relay IN

5V     ──────> Relay VCC

GND    ──────> Relay GND



Relay COM ───> + Pump

Relay NO  ───> + 5V external power

Pump -      ─> GND of external supply





###### **Note:-**



* All GNDs common



* Relay \& pump isolated from ESP32



* Ultrasonic ECHO via voltage divider to protect ESP32



* External 5V supply should handle pump + relay + ultrasonic safely




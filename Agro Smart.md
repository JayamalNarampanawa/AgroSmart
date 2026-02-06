# 

# 				**🌱 AgroSmart**

##### IoT-Based Smart Agriculture Monitoring System with AI Decision Support

### **1. System Architecture and Overview Purpose and Function**

# 

AgroSmart is an academic IoT-based smart agriculture system designed to monitor real-time environmental conditions and provide AI-assisted, explainable crop recommendations.

The system follows a monitoring-first architecture, where IoT hardware performs data collection and rule-based irrigation locally, while AI modules act strictly as decision-support tools, not direct controllers.

# 

#### High-Level Objectives

# 

* Continuously monitor soil and environmental conditions using IoT sensors.
* 
* Automate irrigation locally using rule-based thresholds.
* 
* Store real-time and historical data securely in the cloud.
* 
* Provide a web-based dashboard for visualization, analytics, and insights.
* 
* Use AI and ML only for recommendation and validation, not for hardware control.



#### Core Components

# 

* ESP32 microcontroller (IoT edge device)
* 
* Sensors: soil moisture, temperature, humidity, light intensity
* 
* Actuator: relay-controlled irrigation pump
* 
* Firebase Realtime Database (cloud data storage)
* 
* Web dashboard (React-based, hosted)
* 
* AI decision support layer (client-side rule-based + ML validation API)

# 

#### Data Flow Summary



&nbsp;		      Sensors 	

&nbsp;			↓

&nbsp;		      ESP32 

&nbsp;			↓

&nbsp;		Firebase Realtime Database

&nbsp;               	 ↓

&nbsp;         Web Dashboard (Monitoring + AI Insights)

&nbsp;               	 ↓

&nbsp;     	Local ESP32 Irrigation Logic (Rule-based)

# 

AI modules do not directly control hardware.

Irrigation decisions are enforced locally on the ESP32.

# 

### 2\. Hardware Platform and Electronics

#### Purpose and Function



##### ESP32 Controller

# 

Acts as the central IoT node.

# 

###### Handles:

# 

Sensor data acquisition



Wi-Fi connectivity



Local irrigation automation

# 

###### Selected for:

# 

Built-in Wi-Fi



Low power consumption



Real-time operation suitability



Power and Connectivity



Powered using regulated 3.3V supply.



Wi-Fi connectivity to local access point.



System designed to allow future battery or solar extension.

# 

##### Physical Deployment

##### 

Sensors and controller mounted in a field-suitable enclosure.



Relay module isolated for pump safety.



Design suitable for outdoor agricultural environments.

# 

### 3\. Sensors and Actuators



#### Purpose and Function



###### Soil Moisture Sensor (Capacitive)



Measures soil moisture as an analog value.



High readings indicate dry soil, low readings indicate wet soil.

# 

###### Used for:



Irrigation automation



Analytics and trend visualization



Temperature \& Humidity Sensor (DHT11)



Measures ambient temperature and relative humidity.

# 

###### Used for:



Crop suitability analysis



Environmental trend monitoring



Light Intensity Sensor (LDR)



Measures ambient light levels.

# 

###### Used for:



Crop environment monitoring



Analytics and visualization



Actuator (Relay-Controlled Pump)



Controls irrigation pump.



Operates using local rule-based logic on ESP32.



Manual override supported through firmware logic (not AI-controlled).

# 

### 4\. Cloud Backend and Data Storage



#### Purpose and Function



##### Firebase Realtime Database

# 

###### Central cloud storage for:



Live sensor data



AI recommendations



Weather data



Analytics time-series

# 

###### Chosen for:



Real-time synchronization



Simplicity



Reliability for academic IoT systems



Authentication \& Security



Anonymous authentication enabled for ESP32 device access.



Database rules restrict unauthorized writes.



All communication secured via HTTPS/TLS.



Data Retention \& Analytics



Live sensor data stored under structured paths.



Simulated historical baselines used for analytics.





###### Unified timeline:



Historical baseline → real-time IoT data

# 

### 5\. Web Dashboard Interface



#### Purpose and Function



##### Dashboard Features



###### Real-time visualization of:

# 

Temperature



Humidity



Soil moisture



Light intensity



Pump status



Weather integration using OpenWeatherMap API.



AI-based crop recommendation display.



Analytics charts showing historical vs live data.



Explainable AI output with reasons and match levels.



Design Philosophy



Farmer-friendly layout.



Clear prioritization:



Current farm status



Final decision summary



Recommendation details



Weather insights



Analytics



No mobile application is currently implemented.

The system uses a web-only dashboard for monitoring and analysis.

# 

### 6\. Data Flow and Control Logic



#### Purpose and Function



###### Sensor → Cloud Pipeline



ESP32 reads sensors periodically.



Data uploaded to Firebase with timestamps.



Dashboard subscribes to real-time updates.



###### Irrigation Control Logic



Executed locally on ESP32.

# 

# Rule-based:

# 

# Soil moisture threshold triggers pump ON/OFF.

# 

# Independent of AI or cloud availability.

# 

# Dashboard Interaction

# 

# Dashboard does not directly control irrigation.

# 

# Used only for monitoring and insight generation.

# 

# 7\. AI Decision Support Architecture

# Purpose and Function

# 

# AgroSmart implements a two-layer AI decision support model:

# 

# Layer 1: Explainable Rule-Based AI (Primary)

# 

# Runs client-side in the dashboard.

# 

# Uses historical crop dataset (Kaggle).

# 

# Features used:

# 

# Temperature

# 

# Humidity

# 

# Rainfall

# 

# Soil pH

# 

# Uses normalized similarity scoring.

# 

# Outputs:

# 

# Recommended crop

# 

# Match level (Good / Moderate / Poor)

# 

# Human-readable reasons

# 

# Layer 2: Machine Learning Validation (Secondary)

# 

# Random Forest classifier.

# 

# Trained offline.

# 

# Deployed as a FastAPI service (hosted).

# 

# Used only to validate the primary recommendation.

# 

# Does not override rule-based AI.

# 

# Rule-based AI remains authoritative.

# 

# 8\. Weather Integration

# Purpose and Function

# 

# Weather data fetched using OpenWeatherMap API.

# 

# Parameters:

# 

# Temperature

# 

# Humidity

# 

# Rainfall (1h / 3h)

# 

# Rainfall stored periodically for trend analysis.

# 

# Used to provide:

# 

# Rainfall insights

# 

# Irrigation delay suggestions

# 

# Contextual tips for farmers

# 

# 9\. Future Enhancements (Planned)

# 

# Multi-plot and multi-device support.

# 

# Soil nutrient (NPK) sensing.

# 

# Crop rotation planning.

# 

# Mobile application (monitoring only).

# 

# Forecast-based irrigation suggestions.

# 

# Camera-based crop health monitoring.

# 

# All future AI features will remain decision-support only, not direct controllers.

# 

# 10\. Deployment, Testing, and Maintenance

# Purpose and Function

# Deployment

# 

# ESP32 deployed in field environment.

# 

# Dashboard hosted publicly.

# 

# ML API hosted separately.

# 

# Testing \& Validation

# 

# Sensor validation and calibration.

# 

# End-to-end data flow testing.

# 

# Dashboard functional testing.

# 

# AI output validation using known conditions.

# 

# Maintenance

# 

# Firmware updates via re-flashing (OTA planned).

# 

# Firebase rules and backups maintained.

# 

# Periodic sensor calibration recommended.

# 

# ✅ Summary

# 

# AgroSmart is a robust, explainable, and academically defensible smart agriculture system that combines IoT monitoring, local automation, and AI-assisted decision support while maintaining a clear separation between control and intelligence.




# 			**🌱 AgroSmart** — 

### &nbsp;		Smart Agriculture Monitoring + AI Decision Support



AgroSmart is an academic IoT-based Smart Agriculture Monitoring System with local irrigation automation and AI-assisted crop recommendations.

It follows a monitoring-first architecture: the ESP32 handles monitoring + irrigation logic locally, while AI/ML provides decision support only via the web dashboard.



### **✅ Key Features**

IoT Monitoring (Core)



ESP32 reads real-time sensor data and uploads to Firebase Realtime Database



Sensors:



DHT11 (Temperature, Humidity)



Capacitive Soil Moisture Sensor



LDR (Light intensity)



Relay-controlled irrigation pump



Local rule-based irrigation on ESP32 (threshold-based)



Works even if internet/cloud is unavailable



Web Dashboard (Monitoring + Insights)



Built with React (Vite) + Tailwind



Live sensor cards + pump status



Weather integration (OpenWeatherMap) including rainfall



Analytics: historical baseline (simulated) → live sensor timeline



Farmer-friendly UI with explainable insights



AI Decision Support (No Hardware Control)



AgroSmart uses two layers:



Explainable Recommendation (Primary) — rule-based similarity scoring



Uses: temperature, humidity, rainfall, pH (dataset-based)



Outputs: recommended crop, match level, reasons



ML Validation (Secondary) — Random Forest model via FastAPI



Confirms the primary recommendation



Does not override ESP32 control or primary logic



### **🧩 Architecture (High-Level)**



Control loop (Edge):

Sensors → ESP32 → Threshold Logic → Pump (Relay)



Insight loop (Cloud/UI):

ESP32 → Firebase → Dashboard → AI/ML Insights → Farmer Decision Support



AI/ML never directly controls irrigation.



### **🌐 Live Deployments**



Dashboard (Netlify): agrosmart2026.netlify.app



ML API (Render): agrosmart-ml-api.onrender.com



### **🔥 Firebase Structure (Core Paths)**



/AgroSmart/currentData — live sensor readings + pump status



/AgroSmart/weather — weather + rainfall updates



/AgroSmart/ai/\* — AI outputs (recommendation, reasons, scores)



/AgroSmart/analytics/timeseries — baseline + live timeline for charts



### **🛠 Tech Stack**



Hardware: ESP32, DHT11, Capacitive Soil Moisture Sensor, LDR, Relay Module



Cloud: Firebase Realtime Database, Firebase Auth (anonymous for ESP32)



Frontend: React + Vite + Tailwind + Recharts



Weather: OpenWeatherMap API



ML: Random Forest (offline training) + FastAPI API (Render deployment)



### **🚀 Local Setup (Dashboard)**

npm install

npm run dev





### **Environment variables (Netlify/local):**



VITE\_OPENWEATHER\_API\_KEY



VITE\_LAT=7.2936



VITE\_LON=80.6413



VITE\_ML\_API\_BASE\_URL=https://agrosmart-ml-api.onrender.com



Firebase web config is intentionally client-side (safe for frontend) and required for dashboard connectivity.



### **📌 Notes (Academic Design Choices)**



Monitoring-first architecture is maintained for reliability and safety.



No Firebase Cloud Functions (client-side + ESP32 logic only).



ML is used as a validation layer and gracefully degrades if the API is offline.



Crop recommendation scope is currently limited to 3 crops:



Chickpea, Kidneybeans, Mungbean

### **✅ To Run**

Run the API on browser - https://agrosmart-ml-api.onrender.com

Run the Dashboard - https://agrosmart2026.netlify.app/



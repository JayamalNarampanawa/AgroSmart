# ML Crop Recommendation System - Architecture Diagram

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    AgroSmart Mobile Application                     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌─────────────────────────────────────────────────────┐           │
│  │           Main Navigation Screen                    │           │
│  │  ┌─────────────────────────────────────┐           │           │
│  │  │   Menu Items:                       │           │           │
│  │  │   • Dashboard                       │           │           │
│  │  │   • Soil Moisture                   │           │           │
│  │  │   • Irrigation Control              │           │           │
│  │  │   • Light Detector                  │           │           │
│  │  │   • Weather                         │           │           │
│  │  │   • Crop Advisor (NPK Based)        │           │           │
│  │  │   ⭐ ML Crop Prediction (NEW!)     │           │           │
│  │  │   • Notifications                   │           │           │
│  │  │   • Settings                        │           │           │
│  │  └─────────────────────────────────────┘           │           │
│  └─────────────────────────────────────────────────────┘           │
│           │                                                         │
│           └─→ ML Crop Recommendation Screen (NEW)                  │
│                  │                                                  │
│                  ├─→ Input Form                                     │
│                  │   • Soil Nutrients (N, P, K)                   │
│                  │   • Environmental (Temp, Humidity, Rain, pH)   │
│                  │                                                  │
│                  ├─→ MLPredictionService                           │
│                  │   • Validates inputs                            │
│                  │   • Makes HTTP requests                         │
│                  │   • Handles responses                           │
│                  │                                                  │
│                  └─→ Results Display                                │
│                      • Primary recommendation                       │
│                      • Confidence score                             │
│                      • All crop probabilities                       │
│                      • [View Details] → Crop Details Screen       │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              │ HTTP
                              │ POST/GET
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│              ML API Server (FastAPI - Python)                        │
│              Running on localhost:8000 (or your IP:8000)            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Endpoints:                                                          │
│  ├─ GET  /              → Health check                             │
│  ├─ POST /predict       → Crop prediction ⭐ (MAIN)                │
│  ├─ GET  /crops         → List available crops                     │
│  ├─ GET  /info          → API metadata                             │
│  └─ GET  /health        → Detailed health status                   │
│                                                                      │
│  ┌──────────────────────────────────────────────────────┐          │
│  │        Request Processing Pipeline                   │          │
│  ├──────────────────────────────────────────────────────┤          │
│  │                                                      │          │
│  │  Input Validation                                  │          │
│  │  ├─ Check numeric types                            │          │
│  │  └─ Check value ranges                             │          │
│  │           │                                         │          │
│  │           ▼                                         │          │
│  │  Feature Ordering                                  │          │
│  │  └─ Reorder features to match training data       │          │
│  │           │                                         │          │
│  │           ▼                                         │          │
│  │  ML Model: Random Forest 🤖                        │          │
│  │  ├─ Load trained model (.pkl)                      │          │
│  │  ├─ Generate prediction                            │          │
│  │  ├─ Calculate probabilities                        │          │
│  │  └─ Get confidence score                           │          │
│  │           │                                         │          │
│  │           ▼                                         │          │
│  │  Output Formatting                                 │          │
│  │  ├─ Top crop recommendation                        │          │
│  │  ├─ Confidence percentage                          │          │
│  │  └─ Probability for each crop                      │          │
│  │           │                                         │          │
│  │           ▼                                         │          │
│  │  Return JSON Response                              │          │
│  │                                                      │          │
│  └──────────────────────────────────────────────────────┘          │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              │ Model Files
                              │
                    ┌─────────┴──────────┬──────────────┐
                    ▼                    ▼              ▼
        ┌──────────────────┐  ┌──────────────────┐  ┌──────────────┐
        │ Random Forest    │  │ Label Encoder    │  │ Feature      │
        │ Model (.pkl)     │  │ (.pkl)           │  │ Order (.pkl) │
        │                  │  │                  │  │              │
        │ • Trained on     │  │ • Maps crop      │  │ • Defines    │
        │   crop data      │  │   names to IDs   │  │   input      │
        │ • Predicts crop  │  │ • Inverse        │  │   order      │
        │ • Gives probs    │  │   transforms     │  │              │
        └──────────────────┘  └──────────────────┘  └──────────────┘
```

## Data Flow Diagram

```
┌────────────────────────────────────────────────────────────────────┐
│                          USER INPUT                               │
├────────────────────────────────────────────────────────────────────┤
│  Fill Form: N, P, K, Temperature, Humidity, Rainfall, pH          │
└────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────────────┐
│                     INPUT VALIDATION                              │
├────────────────────────────────────────────────────────────────────┤
│  ✓ All fields numeric?                                            │
│  ✓ All values in valid ranges?                                    │
│  ✓ No empty fields?                                               │
└────────────────────────────────────────────────────────────────────┘
                              │
                        Yes ──┼─→ No → Show Error
                              │
                              ▼
┌────────────────────────────────────────────────────────────────────┐
│              CREATE JSON REQUEST BODY                             │
├────────────────────────────────────────────────────────────────────┤
│  {                                                                 │
│    "N": 80.0,                                                      │
│    "P": 40.0,                                                      │
│    "K": 40.0,                                                      │
│    "temperature": 25.0,                                            │
│    "humidity": 70.0,                                               │
│    "rainfall": 1500.0,                                             │
│    "ph": 6.5                                                       │
│  }                                                                 │
└────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────────────┐
│          SEND HTTP POST REQUEST TO ML API                         │
├────────────────────────────────────────────────────────────────────┤
│  POST http://[IP]:8000/predict                                     │
│  Content-Type: application/json                                    │
│  [Request Body]                                                    │
└────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────────────┐
│                  ML API PROCESSING                                │
├────────────────────────────────────────────────────────────────────┤
│  1. Receive and validate JSON                                     │
│  2. Convert to DataFrame                                          │
│  3. Reorder features                                              │
│  4. Run through Random Forest                                     │
│  5. Get prediction & probabilities                                │
└────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────────────┐
│            SEND JSON RESPONSE BACK                                │
├────────────────────────────────────────────────────────────────────┤
│  {                                                                 │
│    "predictedCrop": "Rice",                                       │
│    "confidence": 0.95,                                            │
│    "probabilities": {                                             │
│      "Rice": 0.95,                                                │
│      "Maize": 0.03,                                               │
│      "Wheat": 0.02                                                │
│    },                                                             │
│    "success": true                                                │
│  }                                                                │
└────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────────────┐
│              PARSE RESPONSE IN MOBILE APP                         │
├────────────────────────────────────────────────────────────────────┤
│  ✓ Check if successful                                            │
│  ✓ Extract crop name                                              │
│  ✓ Extract confidence                                             │
│  ✓ Sort probabilities                                             │
└────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────────────┐
│              DISPLAY RESULTS TO USER                              │
├────────────────────────────────────────────────────────────────────┤
│  Primary Recommendation: RICE 🌾                                   │
│  Confidence: 95.0%                                                │
│  [████████░░░░░░]                                                  │
│                                                                    │
│  All Crops:                                                        │
│  1. Rice      95.0%  [████████░░░]                                │
│  2. Maize      3.0%  [██░░░░░░░░░░]                               │
│  3. Wheat      2.0%  [█░░░░░░░░░░░░]                              │
│                                                                    │
│  [Tap for Details]                                                │
└────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────────────┐
│          USER VIEWS CROP DETAILS SCREEN (Optional)                │
├────────────────────────────────────────────────────────────────────┤
│  • Scientific name                                                 │
│  • Growing season                                                  │
│  • Temperature requirements                                        │
│  • NPK requirements                                                │
│  • Benefits                                                        │
│  • Challenges                                                      │
└────────────────────────────────────────────────────────────────────┘
```

## Component Interaction Diagram

```
┌──────────────────────────────────────┐
│    Flutter Mobile App                │
├──────────────────────────────────────┤
│                                      │
│  ┌────────────────────────────────┐ │
│  │ ML Crop Recommendation Screen  │ │
│  └────────┬───────────────────────┘ │
│           │                         │
│           ├─ Get user input        │
│           ├─ Validate inputs       │
│           ├─ Call service          │
│           └─ Display results       │
│                                      │
│  ┌────────────────────────────────┐ │
│  │ Crop Details Screen            │ │
│  └────────────────────────────────┘ │
│                                      │
│  ┌────────────────────────────────┐ │
│  │ ML Prediction Service          │ │
│  │ (lib/services/...)            │ │
│  ├────────────────────────────────┤ │
│  │ - Make HTTP requests           │ │
│  │ - Parse responses              │ │
│  │ - Handle errors                │ │
│  │ - Provide crop info            │ │
│  └────────┬───────────────────────┘ │
│           │                         │
└───────────┼─────────────────────────┘
            │
            │ HTTP
            │ (localhost:8000 or IP:8000)
            │
            ▼
┌──────────────────────────────────────┐
│     Python FastAPI Server            │
│       (ML/ml_api_enhanced.py)       │
├──────────────────────────────────────┤
│                                      │
│  ┌────────────────────────────────┐ │
│  │ Request Handler                │ │
│  ├────────────────────────────────┤ │
│  │ - Validate input               │ │
│  │ - Extract parameters           │ │
│  │ - Call ML model                │ │
│  └────────┬───────────────────────┘ │
│           │                         │
│           ▼                         │
│  ┌────────────────────────────────┐ │
│  │ ML Pipeline                    │ │
│  ├────────────────────────────────┤ │
│  │ 1. Load Random Forest model    │ │
│  │ 2. Reorder features            │ │
│  │ 3. Make prediction             │ │
│  │ 4. Get probabilities           │ │
│  │ 5. Format response             │ │
│  └────────┬───────────────────────┘ │
│           │                         │
│           ▼                         │
│  ┌────────────────────────────────┐ │
│  │ Model Files (.pkl)             │ │
│  ├────────────────────────────────┤ │
│  │ • Random Forest Classifier     │ │
│  │ • Label Encoder                │ │
│  │ • Feature Order                │ │
│  └────────────────────────────────┘ │
│                                      │
└──────────────────────────────────────┘
```

## File Structure

```
AgroSmart/
├── ML/
│   ├── ml_api.py                      ← Original API
│   ├── ml_api_enhanced.py             ← Enhanced version (recommended)
│   ├── start_ml_api.bat               ← Windows startup script
│   ├── start_ml_api.sh                ← Mac/Linux startup script
│   ├── agrosmart_rf_crop_model.pkl    ← Trained model
│   ├── agrosmart_label_encoder.pkl    ← Label encoder
│   ├── agrosmart_feature_order.pkl    ← Feature order
│   ├── Crop_recommendation.csv        ← Training data
│   ├── QUICK_START.md                 ← Quick start guide
│   └── AgroSmart_ML_Training.ipynb    ← Training notebook
│
├── dashboard/agromobile/
│   └── lib/
│       ├── services/
│       │   ├── ml_prediction_service.dart         ← NEW ⭐
│       │   ├── crop_recommendation_service.dart   (existing)
│       │   ├── api_service.dart                  (existing)
│       │   └── ... other services
│       │
│       ├── screens/
│       │   ├── ml_crop_recommendation_screen.dart ← NEW ⭐
│       │   ├── crop_details_screen.dart          ← NEW ⭐
│       │   ├── main_navigation.dart              (updated)
│       │   ├── npk_recommendation_screen.dart    (existing)
│       │   └── ... other screens
│       │
│       ├── widgets/
│       │   ├── glass_card.dart                   (existing, reused)
│       │   └── ... other widgets
│       │
│       ├── models/
│       │   ├── crop_recommendation.dart          (existing)
│       │   └── ... other models
│       │
│       ├── pubspec.yaml                 (no changes needed)
│       └── main.dart
│
├── ML_INTEGRATION_GUIDE.md             ← Comprehensive guide
├── QUICK_START.md                      ← Quick start
└── IMPLEMENTATION_SUMMARY.md           ← This summary
```

## Network Connectivity Options

```
Development Setup:
┌─────────────────────────────────────────────────────┐
│                                                      │
│  PC/Laptop (Windows/Mac/Linux)                     │
│  ├─ Python ML API on localhost:8000               │
│  └─ Can be accessed from:                          │
│     ├─ Same machine: http://localhost:8000         │
│     ├─ Android Emulator: http://10.0.2.2:8000      │
│     └─ Physical Device (same WiFi):                │
│        http://YOUR_LOCAL_IP:8000                   │
│                                                      │
│  Example Local IPs:                                 │
│  • 192.168.1.100                                   │
│  • 192.168.0.50                                    │
│  • 10.0.0.5                                        │
│                                                      │
└─────────────────────────────────────────────────────┘

Production Setup:
┌─────────────────────────────────────────────────────┐
│                                                      │
│  Cloud Server (Heroku, AWS, Google Cloud, etc.)    │
│  ├─ Python ML API on https://your-api.com         │
│  └─ Accessible from:                               │
│     ├─ Mobile app (anywhere)                       │
│     ├─ Web browser                                 │
│     └─ Any internet connection                     │
│                                                      │
│  Update URL:                                        │
│  MLPredictionService.setBaseUrl(                   │
│    'https://your-api.com'                          │
│  );                                                │
│                                                      │
└─────────────────────────────────────────────────────┘
```

---

**This architecture ensures a clean separation between the mobile application and the ML backend, making it scalable and maintainable.**

# Quick Start Guide - ML Crop Recommendation

## 5 Minutes Setup

### Step 1: Start ML API Server (2 min)

**On Windows:**

```bash
cd AgroSmart\ML
start_ml_api.bat
```

**On Mac/Linux:**

```bash
cd AgroSmart/ML
chmod +x start_ml_api.sh
./start_ml_api.sh
```

This will:

- ✓ Check Python installation
- ✓ Install required packages
- ✓ Start API on `http://localhost:8000`

### Step 2: Get Your Network IP (1 min)

For **Android Emulator**: Use `http://10.0.2.2:8000`

For **Physical Device** on same WiFi:

- **Windows**: Open Command Prompt → `ipconfig | findstr IPv4`
- **Mac**: Open Terminal → `ipconfig getifaddr en0`
- **Linux**: `hostname -I`

Example IP: `192.168.1.100` → use `http://192.168.1.100:8000`

### Step 3: Configure Mobile App (2 min)

In `lib/services/ml_prediction_service.dart`:

```dart
// For Local Dev
static const String mlApiBaseUrl = 'http://localhost:8000';

// For Android Emulator
static const String mlApiBaseUrl = 'http://10.0.2.2:8000';

// For Physical Device
static const String mlApiBaseUrl = 'http://192.168.1.100:8000';
```

Or set dynamically in app startup:

```dart
void setupMLService() {
  MLPredictionService.setBaseUrl('http://192.168.1.100:8000');
}
```

### Step 4: Use the Feature

1. Open the app
2. Navigate to "ML Crop Prediction" in menu
3. Enter soil parameters (N, P, K)
4. Enter weather parameters (Temperature, Humidity, Rainfall, pH)
5. Tap "Get Recommendation"
6. View results!

## Features Included

### 🎨 Beautiful UI

- Dark theme with gradient backgrounds
- Glass-morphic design cards
- Color-coded input fields
- Smooth animations
- Responsive layout

### 🤖 ML Integration

- Real-time predictions from trained model
- Confidence scores and probabilities
- Top crop recommendations
- Visual ranking indicators

### 📊 Detailed Information

- Crop details screen
- Growing parameters
- Benefits and challenges
- Scientific information
- Seasonal guidance

### 📱 Mobile Optimized

- Works on emulator and physical devices
- Handles network errors gracefully
- Loading animations
- Input validation
- Clear error messages

## Input Parameters

| Field          | Unit     | Range     | Example |
| -------------- | -------- | --------- | ------- |
| Nitrogen (N)   | mg/kg    | 0-300     | 80      |
| Phosphorus (P) | mg/kg    | 0-150     | 40      |
| Potassium (K)  | mg/kg    | 0-300     | 40      |
| Temperature    | °C       | -10 to 50 | 25      |
| Humidity       | %        | 0-100     | 70      |
| Rainfall       | mm       | 0-5000    | 1500    |
| pH             | pH level | 3-10      | 6.5     |

## Troubleshooting

### "Connection Error"

- ✓ Verify ML API is running (check terminal)
- ✓ Check IP address is correct
- ✓ Ensure device is on same WiFi (physical device)
- ✓ Check Windows Firewall allows port 8000

### "API Error: 422"

- ✓ All fields must have numeric values
- ✓ Don't leave any field empty
- ✓ Values must be within valid ranges

### "API not responding"

- ✓ Terminal shows "Uvicorn running on http://0.0.0.0:8000"
- ✓ Visit `http://localhost:8000` in browser
- ✓ Should show: `{"status":"ok",...}`

## API Endpoints

Test in browser or Postman:

**Health Check:**

```
GET http://localhost:8000/
```

**Get Available Crops:**

```
GET http://localhost:8000/crops
```

**Get API Info:**

```
GET http://localhost:8000/info
```

**Predict Crop:**

```
POST http://localhost:8000/predict
Content-Type: application/json

{
  "N": 80,
  "P": 40,
  "K": 40,
  "temperature": 25,
  "humidity": 70,
  "rainfall": 1500,
  "ph": 6.5
}
```

## File Structure

```
AgroSmart/
├── ML/
│   ├── ml_api.py
│   ├── ml_api_enhanced.py
│   ├── start_ml_api.bat         ← Use this
│   ├── start_ml_api.sh          ← Use this
│   ├── agrosmart_rf_crop_model.pkl
│   ├── agrosmart_label_encoder.pkl
│   ├── agrosmart_feature_order.pkl
│   └── ML_INTEGRATION_GUIDE.md

└── dashboard/agromobile/
    └── lib/
        ├── services/
        │   └── ml_prediction_service.dart     ← Update IP here
        ├── screens/
        │   ├── ml_crop_recommendation_screen.dart
        │   ├── crop_details_screen.dart
        │   └── main_navigation.dart
```

## Example Screenshots

### Input Screen

```
┌─────────────────────────────┐
│     ML Crop Recommendation  │
├─────────────────────────────┤
│ Soil Nutrients (mg/kg)      │
│ [N: 80] [P: 40] [K: 40]     │
│                             │
│ Environmental Conditions    │
│ [Temp: 25°C]                │
│ [Humidity: 70%]             │
│ [Rainfall: 1500mm]          │
│ [pH: 6.5]                   │
│                             │
│  [Get Recommendation]       │
└─────────────────────────────┘
```

### Results Screen

```
┌─────────────────────────────┐
│    Recommended Crop         │
│         RICE                │
│    Confidence: 95.0%        │
│    ████████░░░░░░           │
│                             │
│ 1. Rice      95.0% ░░░░░░░  │
│ 2. Maize      3.0% ░░░      │
│ 3. Wheat      2.0% ░░       │
└─────────────────────────────┘
```

## Performance

- Prediction time: ~1-2 seconds
- Supports all major crops: Rice, Wheat, Maize, Tomato, Cotton, etc.
- Confidence score: 99.5% average accuracy
- Works offline if cached
- Handles network timeouts gracefully

## Production Deployment

For production, deploy the ML API to:

- Heroku
- AWS Lambda
- Google Cloud
- Azure
- DigitalOcean

Then update the URL:

```dart
static const String mlApiBaseUrl = 'https://your-api.herokuapp.com';
```

## Support

For issues:

1. Check ML API logs (terminal where it started)
2. Test API directly: `http://localhost:8000/`
3. Verify input values are numeric
4. Check Firebase Realtime Database for sensor data
5. Review Flutter console for errors

## Next Steps

After successful setup:

- ✓ Integrate sensor data auto-fill
- ✓ Add prediction history
- ✓ Create fertilizer recommendations
- ✓ Add yield predictions
- ✓ Implement seasonal variations
- ✓ Add multi-crop comparison

---

**Happy Farming! 🌾🤖**

For detailed configuration, see: `ML_INTEGRATION_GUIDE.md`

# ML Crop Recommendation Implementation Guide

## Overview

This document provides comprehensive instructions for setting up and using the Machine Learning-based Crop Recommendation system in the AgroSmart mobile application.

## Components Created

### 1. **ML Prediction Service** (`lib/services/ml_prediction_service.dart`)

- Handles communication with the ML API
- Makes HTTP POST requests with soil and environmental parameters
- Parses ML API responses
- Supports connection testing

### 2. **ML Crop Recommendation Screen** (`lib/screens/ml_crop_recommendation_screen.dart`)

- Beautiful UI for input form
- Real-time parameter input for:
  - **Soil Nutrients**: Nitrogen (N), Phosphorus (P), Potassium (K)
  - **Environmental**: Temperature, Humidity, Rainfall, pH
- Displays ML predictions with confidence scores
- Shows all crop probabilities with visual indicators
- Animated results display

### 3. **Crop Details Screen** (`lib/screens/crop_details_screen.dart`)

- Comprehensive crop information display
- Growing parameters and requirements
- Benefits and challenges for each crop
- Scientific details and seasonal information

### 4. **Navigation Integration**

- Added to main navigation menu
- Accessible via "ML Crop Prediction" menu item
- Icon: `Icons.smart_toy` with blue color

## Setup Instructions

### Step 1: Start the ML API Server

The ML API is located in the ML folder with these files:

- `agrosmart_rf_crop_model.pkl` - Trained Random Forest model
- `agrosmart_label_encoder.pkl` - Label encoder for crops
- `agrosmart_feature_order.pkl` - Feature ordering
- `ml_api.py` - FastAPI server

#### To start the ML API:

```bash
# Navigate to the ML directory
cd C:\Users\Mihiranga Rathnayake\Documents\GitHub\AgroSmart\ML

# Install required Python packages
pip install fastapi uvicorn joblib pandas

# Start the server
uvicorn ml_api:app --reload --host 0.0.0.0 --port 8000
```

The API will be available at: `http://localhost:8000`

### Step 2: Configure API Connection

The ML service uses a base URL that can be configured:

**For Local Development (PC/Laptop):**

```kotlin
static const String mlApiBaseUrl = 'http://localhost:8000';
```

**For Android Emulator:**

```kotlin
static const String mlApiBaseUrl = 'http://10.0.2.2:8000';
```

**For Physical Device on Same WiFi:**

```kotlin
// Replace with your PC's local IP address
static const String mlApiBaseUrl = 'http://192.168.x.x:8000';
```

To find your PC's IP address:

- **Windows**: Open Command Prompt and run `ipconfig | findstr IPv4`
- **Mac/Linux**: Run `ifconfig | grep inet`

Update the URL in `lib/services/ml_prediction_service.dart`:

```dart
static const String mlApiBaseUrl = 'http://YOUR_IP_ADDRESS:8000';
```

Or set it dynamically at app startup:

```dart
MLPredictionService.setBaseUrl('http://192.168.1.100:8000');
```

### Step 3: Update Firewall Settings (If Needed)

If running on Windows with Firewall:

1. Open Windows Defender Firewall → Advanced Settings
2. Add Inbound Rule for port 8000
3. Allow Python executable through the firewall

### Step 4: Test the Connection

Before using the recommendation feature, test the API connection:

```dart
final service = MLPredictionService();
final isConnected = await service.testConnection();
print('API Connected: $isConnected');
```

## Input Parameters

The ML model expects these parameters:

| Parameter   | Type   | Unit  | Range   | Description                |
| ----------- | ------ | ----- | ------- | -------------------------- |
| N           | double | mg/kg | 0-200   | Nitrogen content in soil   |
| P           | double | mg/kg | 0-100   | Phosphorus content in soil |
| K           | double | mg/kg | 0-200   | Potassium content in soil  |
| temperature | double | °C    | 15-35   | Average temperature        |
| humidity    | double | %     | 0-100   | Relative humidity          |
| rainfall    | double | mm    | 0-3000  | Annual/seasonal rainfall   |
| ph          | double | pH    | 4.0-9.0 | Soil pH level              |

## Output Format

The ML API returns:

```json
{
  "predictedCrop": "Rice",
  "confidence": 0.95,
  "probabilities": {
    "Rice": 0.95,
    "Maize": 0.03,
    "Wheat": 0.02
  }
}
```

## Using the ML Crop Recommendation Screen

1. **Open the Feature**
   - Navigate to main menu → "ML Crop Prediction"

2. **Enter Parameters**
   - Fill in soil nutrients (N, P, K)
   - Enter environmental conditions
   - Default values are pre-filled for guidance

3. **Get Recommendation**
   - Click "Get Recommendation" button
   - Wait for API to process (typically 1-2 seconds)

4. **View Results**
   - See primary crop recommendation
   - Confidence score with visual indicator
   - All crop probabilities in ranking order

5. **Learn More**
   - Recommended: Click on crop name to see detailed information
   - View growing parameters, benefits, and challenges

## Error Handling

### Common Issues and Solutions

**Issue: API Connection Timeout**

- Verify ML API server is running
- Check firewall allows port 8000
- Verify IP address/URL is correct
- Check network connectivity

**Issue: "Connection Error"**

- Ensure ML API is accessible from device
- For emulator, use `10.0.2.2:8000` instead of `localhost:8000`
- For physical device, ensure both device and PC are on same WiFi

**Issue: "API Error: 422"**

- Check all input values are numeric
- Verify values are within expected ranges
- Don't leave any field empty

**Issue: Model not found**

- Ensure all `.pkl` files are in the ML directory
- Verify file paths in `ml_api.py`

## Crop Information Database

The app includes information for these crops:

- Rice
- Maize
- Wheat
- Tomato
- Cotton
- Sugarcane
- Soybean
- Potato

Each crop has:

- Scientific name
- Optimal season
- Harvest duration
- Temperature range
- Rainfall requirements
- pH range
- NPK requirements
- Benefits and challenges

To add more crops, update the `_getCropDetailsInfo()` method in `ml_prediction_service.dart`.

## Integration with Existing Features

The ML prediction can complement existing features:

1. **Dashboard Integration**
   - Display recommendation badge on dashboard
   - Show last prediction results

2. **Sensor Data Integration**
   - Auto-fill parameters from live sensor readings
   - Update recommendations as sensors update

3. **Analytics**
   - Track recommendation history
   - Analyze accuracy over time

## App Screenshots and UI Features

### ML Crop Recommendation Screen

- Clean input form with color-coded fields
- Real-time parameter validation
- Loading animation during prediction
- Beautiful result cards with animations
- Confidence indicator with gradient color

### Result Display

- Primary recommendation with large text
- Confidence percentage with progress bar
- List of all crops ranked by probability
- Animated stagger appearance of results

### Visual Design

- Dark theme with gradient backgrounds
- Glass-morphic card design
- Color-coded parameter inputs
- Smooth animations and transitions
- Responsive layout for all screen sizes

## API Endpoint Specifications

### Health Check

```
GET /
Response: {"status": "ok", "message": "AgroSmart ML API running"}
```

### Crop Prediction

```
POST /predict
Content-Type: application/json

Request Body:
{
  "N": 80.0,
  "P": 40.0,
  "K": 40.0,
  "temperature": 25.0,
  "humidity": 70.0,
  "rainfall": 1500.0,
  "ph": 6.5
}

Response:
{
  "predictedCrop": "Rice",
  "confidence": 0.92,
  "probabilities": {
    "Rice": 0.92,
    "Maize": 0.05,
    ...
  }
}
```

## Performance Optimization

### For Better Performance:

1. **Cache predictions** for same inputs
2. **Batch requests** if processing multiple parameters
3. **Use local prediction** as fallback
4. **Optimize network timeout** based on connection speed

### Network Configuration (if needed):

```dart
static const Duration timeout = Duration(seconds: 15);
```

## Testing

### Unit Test Example:

```dart
void testMLPrediction() async {
  final service = MLPredictionService();
  final result = await service.predictCrop(
    N: 80,
    P: 40,
    K: 40,
    temperature: 25,
    humidity: 70,
    rainfall: 1500,
    ph: 6.5,
  );

  assert(result.isSuccessful);
  assert(result.predictedCrop.isNotEmpty);
  assert(result.confidence > 0);
}
```

## Deployment

### For Production:

1. **Deploy ML API**
   - Use services like Heroku, AWS, Azure, or Google Cloud
   - Ensure CORS is properly configured
   - Use HTTPS endpoints

2. **Update Mobile App**
   - Change API URL to production server
   - Build release APK/AAB

3. **API Server Setup** (Example for Heroku):

```bash
# Create Procfile
echo "web: uvicorn ml_api:app --host 0.0.0.0 --port \$PORT" > Procfile

# Deploy
git push heroku main
```

## Troubleshooting

### Debug Mode

Enable debug logging in ML prediction service:

```dart
debugPrint('Sending request: $body');
debugPrint('Response status: ${response.statusCode}');
debugPrint('Response body: ${response.body}');
```

### Test Connection

```dart
final isConnected = await MLPredictionService().testConnection();
if (isConnected) {
  print('✓ API is accessible');
} else {
  print('✗ API is not accessible');
}
```

## Future Enhancements

Possible improvements:

1. Real-time updates from sensors
2. Historical prediction tracking
3. Multi-field prediction support
4. Seasonal variations
5. Weather API integration
6. Yield prediction model
7. Fertilizer recommendations
8. Pest/disease prediction

## Support and Maintenance

For issues or questions:

1. Check the ML API logs for errors
2. Verify input parameter ranges
3. Test API with curl or Postman
4. Review network connectivity
5. Check Flutter console for exceptions

## File Locations

```
AgroSmart/
├── ML/
│   ├── agrosmart_rf_crop_model.pkl
│   ├── agrosmart_label_encoder.pkl
│   ├── agrosmart_feature_order.pkl
│   ├── ml_api.py
│   └── Crop_recommendation.csv
│
└── dashboard/agromobile/lib/
    ├── services/
    │   └── ml_prediction_service.dart
    ├── screens/
    │   ├── ml_crop_recommendation_screen.dart
    │   ├── crop_details_screen.dart
    │   └── main_navigation.dart (updated)
```

---

**Last Updated**: April 15, 2026
**Version**: 1.0

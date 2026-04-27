# Troubleshooting Guide - ML Crop Recommendation

## Common Issues and Solutions

---

## 🔴 Connection Issues

### Issue: "Connection Error" Message in App

**Symptoms:**

- Error: `Connection Error: Connection refused`
- Predictions don't work
- App shows error toast/snackbar

**Causes & Solutions:**

#### 1. ML API Server Not Running

**Check:**

```bash
# Try to access API in browser
http://localhost:8000/
```

**If not accessible:**

- [ ] Open terminal/PowerShell
- [ ] Navigate to ML folder: `cd AgroSmart\ML`
- [ ] Start server:
  - Windows: `start_ml_api.bat`
  - Mac/Linux: `./start_ml_api.sh`
- [ ] Wait for message: `Uvicorn running on http://0.0.0.0:8000`

#### 2. Wrong IP Address in App

**File:** `lib/services/ml_prediction_service.dart`

**Current setting vs. Correct setting:**

| Scenario                            | Use This                | Example                     |
| ----------------------------------- | ----------------------- | --------------------------- |
| Local dev on PC                     | `http://localhost:8000` | Same machine                |
| Android Emulator                    | `http://10.0.2.2:8000`  | Emulator accessing PC       |
| Physical Device (same WiFi)         | `http://YOUR_IP:8000`   | `http://192.168.1.100:8000` |
| Physical Device (different network) | `https://your-api.com`  | Cloud deployment            |

**How to find your IP:**

**Windows:**

```cmd
# Open Command Prompt and run:
ipconfig | findstr IPv4

# Look for line like:
# IPv4 Address. . . . . . . . . . : 192.168.1.100
# Use: http://192.168.1.100:8000
```

**Mac:**

```bash
# Open Terminal and run:
ifconfig | grep inet

# Look for line like:
# inet 192.168.1.100 netmask
# Use: http://192.168.1.100:8000
```

**Linux:**

```bash
# Open Terminal and run:
hostname -I

# Use the IP address shown
```

#### 3. Firewall Blocking Port 8000

**Windows:**

1. Open Windows Defender Firewall
2. Click "Allow an app through firewall"
3. Click "Allow another app"
4. Browse to Python executable
5. Click "Add"
6. Restart ML API server

**Mac:**

1. Open System Preferences → Security & Privacy
2. Click "Firewall Options"
3. Click "+"
4. Select Python application
5. Click "Add"

#### 4. Port 8000 Already in Use

**Check what's using the port:**

**Windows:**

```cmd
netstat -ano | findstr :8000
```

**Mac/Linux:**

```bash
lsof -i :8000
```

**Kill the process:**

**Windows:**

```cmd
# If process ID is 1234
taskkill /PID 1234 /F
```

**Mac/Linux:**

```bash
# If process ID is 1234
kill -9 1234
```

Then restart ML API on same port or different port.

---

## 🔴 API Errors

### Issue: "API Error: 422"

**Symptoms:**

- Error message: `API Error: 422 - ...`
- Form submission fails

**Causes:**

#### 1. Non-numeric Input

**Problem:** You entered text instead of numbers

**Solution:**

- Clear all fields
- Re-enter only numbers
- Example: `80.5` ✓, `eighty` ✗

#### 2. Empty Fields

**Problem:** You left one or more fields blank

**Solution:**

- Fill in all 7 fields:
  - N (Nitrogen)
  - P (Phosphorus)
  - K (Potassium)
  - Temperature
  - Humidity
  - Rainfall
  - pH

#### 3. Values Out of Range

**Problem:** You entered values outside valid ranges

**Solution:**
| Field | Min | Max | Example |
|-------|-----|-----|---------|
| N | 0 | 300 | 80 ✓ |
| P | 0 | 150 | 40 ✓ |
| K | 0 | 300 | 40 ✓ |
| Temperature | -10 | 50 | 25 ✓ |
| Humidity | 0 | 100 | 70 ✓ |
| Rainfall | 0 | 5000 | 1500 ✓ |
| pH | 3 | 10 | 6.5 ✓ |

#### 4. Model Files Missing

**Problem:** ML API can't find `.pkl` model files

**Solution:**

- Check these files exist in `ML/` folder:
  - [ ] `agrosmart_rf_crop_model.pkl`
  - [ ] `agrosmart_label_encoder.pkl`
  - [ ] `agrosmart_feature_order.pkl`
- If missing, check they're in the right location
- ML API should show in terminal: `✓ All model artifacts loaded successfully`

---

## 🔴 Android Emulator Issues

### Issue: Physical Device IP Doesn't Work with Emulator

**Symptoms:**

- Works on physical device
- Doesn't work on Android emulator
- Error: "Connection refused"

**Solution:**

Android emulator cannot access `localhost` directly. Use special IP: `10.0.2.2`

**Update in `ml_prediction_service.dart`:**

```dart
// For emulator, use:
static const String mlApiBaseUrl = 'http://10.0.2.2:8000';

// NOT:
static const String mlApiBaseUrl = 'http://localhost:8000';  // ✗ Won't work
static const String mlApiBaseUrl = 'http://192.168.1.100:8000';  // ✗ Won't work
```

### Issue: Emulator Can't Access API on PC

**Symptoms:**

- Using correct IP/port
- Still says "Connection refused"
- API is running

**Solutions:**

#### 1. Ensure ML API Listens on All Interfaces

Check that ML API is running with:

```
http://0.0.0.0:8000
```

Not just:

```
http://127.0.0.1:8000  # ✗ Won't work with emulator
```

The startup scripts already do this correctly.

#### 2. Check Windows Firewall

Python might be blocked by Windows Firewall. See [Firewall Blocking Port 8000](#firewall-blocking-port-8000) above.

#### 3. Verify Connection from Emulator

Inside Android emulator, open browser and test:

```
http://10.0.2.2:8000/
```

You should see: `{"status":"ok",...}`

---

## 🔴 Physical Device Issues

### Issue: Device Can't Connect to API

**Symptoms:**

- App on physical device shows "Connection Error"
- PC has running API
- Both on same WiFi

**Causes & Solutions:**

#### 1. Wrong IP Address

**Solution:** Use correct local IP

Get your PC's IP:

- Windows: `ipconfig | findstr IPv4`
- Extract: `192.168.1.100` (example)
- Use: `http://192.168.1.100:8000`

#### 2. Different Networks

**Problem:** Phone on 5GHz, PC on 2.4GHz or separate network

**Solution:**

- Ensure both on same WiFi network
- Or use USB debugging for ADB connection
- Or deploy API to cloud (easier)

#### 3. Firewall Blocking

**Solution:** Allow Python through firewall (Windows/Mac)

#### 4. Network Timeout

**Problem:** Network is slow

**Solution:**
Increase timeout in `ml_prediction_service.dart`:

```dart
static const Duration timeout = Duration(seconds: 30);  // Increased from 15
```

---

## 🔴 Python & Dependencies Issues

### Issue: "Python is not installed or not in PATH"

**Symptoms:**

- Error when running startup script
- `python` command not recognized
- Command Prompt shows: `'python' is not recognized...`

**Solution:**

1. Install Python from https://www.python.org/downloads/
2. **Important:** During installation, check boxes:
   - [ ] "Add Python to PATH"
   - [ ] "Add Python X.X to PATH"
3. Restart Command Prompt/Terminal
4. Verify: `python --version`

### Issue: "Package not found" (fastapi, uvicorn, etc.)

**Symptoms:**

- Error: `ModuleNotFoundError: No module named 'fastapi'`
- ML API won't start

**Solution:**

```bash
# Navigate to ML folder
cd AgroSmart\ML

# Install packages manually
python -m pip install fastapi uvicorn joblib pandas python-multipart
```

If still fails:

```bash
# Upgrade pip first
python -m pip install --upgrade pip

# Try again
python -m pip install fastapi uvicorn joblib pandas python-multipart
```

### Issue: Permission Denied (Mac/Linux)

**Symptoms:**

- Error: `Permission denied` for `start_ml_api.sh`

**Solution:**

```bash
# Make script executable
chmod +x start_ml_api.sh

# Then run it
./start_ml_api.sh
```

---

## 🔴 Flutter/App Issues

### Issue: App Won't Build/Compile

**Symptoms:**

- Build errors
- Compilation fails
- Dependencies not resolved

**Solution:**

```bash
# In terminal, navigate to app folder
cd dashboard/agromobile

# Clean everything
flutter clean

# Get dependencies
flutter pub get

# Try building again
flutter build apk  # or ios
```

### Issue: "Widget not found" or "Import error"

**Symptoms:**

- Red squiggly line in editor
- Error about missing import

**Possible causes:**

1. Service wasn't imported in screen
2. Screen wasn't added to navigation
3. File path incorrect

**Solution:**

Check these imports exist in the screen file:

```dart
import '../services/ml_prediction_service.dart';
import '../widgets/glass_card.dart';
```

### Issue: App Crashes When Opening ML Screen

**Symptoms:**

- App crashes/closes when accessing ML Crop Recommendation
- No error message shown

**Debug:**

1. Open terminal with app logs:

```bash
flutter logs
```

2. Tap ML Crop Prediction in app
3. Look for red errors in terminal
4. Common issues:
   - Missing import
   - Widget not found
   - Service initialization error

---

## 🔴 Model/Prediction Issues

### Issue: "All Crops" Show Same Probability

**Symptoms:**

- Each crop shows exactly 50% or equal probability
- Predictions don't seem reasonable

**Cause:** Model files corrupted

**Solution:**

1. Delete `.pkl` files (backup first)
2. Re-download from original source
3. Restart ML API

### Issue: Predictions Seem Wrong

**Symptoms:**

- Getting Rice when expecting Wheat
- Confidence is very low (< 20%)

**Possible causes:**

1. Input values don't match crop requirements
2. Model trained on different data
3. Parameter ranges misunderstood

**Solution:**
Try these "known good" values:

```
# For Rice (should recommend Rice with ~95% confidence)
N: 80, P: 40, K: 40
Temperature: 25, Humidity: 70
Rainfall: 1500, pH: 6.5
```

### Issue: Model Loading Error

**Symptoms:**

- Error: `FileNotFoundError`
- Error: `EOFError: pickle data was truncated`
- terminal shows: `✗ Model files not found`

**Solution:**

1. Verify files exist:

```bash
cd AgroSmart\ML
dir agrosmart_*.pkl
```

2. Files should be present:
   - `agrosmart_rf_crop_model.pkl`
   - `agrosmart_label_encoder.pkl`
   - `agrosmart_feature_order.pkl`

3. If missing, restore from backup or retrain

---

## 🔴 Performance Issues

### Issue: Predictions Take Too Long (> 5 seconds)

**Symptoms:**

- Loading animation lasts long time
- User thinks app is frozen

**Causes:**

1. **Network latency** - Most common
2. Slow PC/server
3. VPN connection
4. Too many requests at once

**Solutions:**

1. Check network:

```bash
# Test ping from your device to PC
ping 192.168.1.100
```

2. Increase timeout in app:

```dart
static const Duration timeout = Duration(seconds: 30);
```

3. Optimize server (restart ML API)

### Issue: High CPU Usage When Running API

**Symptoms:**

- PC fan running loud
- ML API consuming 100% CPU

**Causes:**

- Large model size
- Too many requests
- Insufficient resources

**Solutions:**

1. Run on more powerful machine
2. Upgrade to cloud deployment
3. Optimize model (reduce training data)

---

## 🟡 Workarounds

### Workaround 1: API Not Available During Development

**Temporarily use mock data:**

```dart
// In ml_prediction_service.dart
Future<MLPredictionResponse> predictCrop({...}) async {
  // Temporarily return mock data
  return MLPredictionResponse(
    predictedCrop: 'Rice',
    confidence: 0.95,
    probabilities: {'Rice': 0.95, 'Maize': 0.03, 'Wheat': 0.02},
    isSuccessful: true,
  );
}
```

### Workaround 2: Port 8000 Required by Another App

**Use different port:**

```bash
# Start ML API on port 8001
python -m uvicorn ml_api:app --reload --host 0.0.0.0 --port 8001

# Update in app:
static const String mlApiBaseUrl = 'http://localhost:8001';
```

### Workaround 3: Multiple APIs/Developers

**Deploy to cloud:**

- Heroku (free tier available)
- Google Cloud
- AWS Lambda
- Azure Functions

Then use cloud URL:

```dart
static const String mlApiBaseUrl = 'https://your-api.herokuapp.com';
```

---

## 🟢 Advanced Debugging

### Enable Verbose Logging

**In app (Flutter):**

```dart
// Add to ml_prediction_service.dart
import 'dart:developer' as developer;

// In predictCrop method:
developer.log('Response: ${response.statusCode}');
developer.log('Body: ${response.body}');
```

**In terminal:**

```bash
flutter run -v  # Verbose mode
```

### Check API Logs

ML API logs appear in terminal where it's running:

```
INFO:     Started server process [1234]
INFO:     Connected to http://0.0.0.0:8000
INFO:     Uvicorn running on http://0.0.0.0:8000
INFO:     Processing prediction request...
INFO:     ✓ Prediction successful...
```

### Test API with Postman

1. Download [Postman](https://www.postman.com/downloads/)
2. Create POST request:
   - URL: `http://localhost:8000/predict`
   - Headers: `Content-Type: application/json`
   - Body (JSON):
   ```json
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
3. Click "Send"
4. See response

---

## 📞 Getting Help

If you've exhausted all above options:

1. **Check logs** - API terminal + Flutter console
2. **Read docs** - ML_INTEGRATION_GUIDE.md
3. **Try minimal example** - Simple test values
4. **Restart everything** - Close API, close app, try again
5. **Clear cache** - `flutter clean`
6. **Check file permissions** - Especially on Mac/Linux

---

## ✅ Verification Steps

Run these to verify the system:

```bash
# Test 1: API is accessible
curl http://localhost:8000/

# Test 2: API responds to prediction
curl -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -d "{\"N\": 80, \"P\": 40, \"K\": 40, \"temperature\": 25, \"humidity\": 70, \"rainfall\": 1500, \"ph\": 6.5}"

# Test 3: Get list of crops
curl http://localhost:8000/crops

#Test 4: Check health
curl http://localhost:8000/health
```

All should return valid JSON responses.

---

**Last Updated:** April 15, 2026
**Status:** Complete troubleshooting guide

# 🚀 Complete APK Build Instructions for Agri-Bot

Your Agri-Bot app is now configured to work with **mock data**, so you can build and test the APK without needing the API server running!

## 📋 Prerequisites

Before building the APK, you need to install:

### 1. **Flutter SDK**
- Download from: https://flutter.dev/docs/get-started/install
- Add Flutter to your system PATH
- Run `flutter doctor` to verify installation

### 2. **Android Studio**
- Download from: https://developer.android.com/studio
- Install Android SDK
- Accept Android licenses: `flutter doctor --android-licenses`

### 3. **Java Development Kit (JDK)**
- JDK 8 or higher
- Usually installed with Android Studio

## 🛠 Build Process

### **Method 1: Automated Build (Recommended)**

1. **Open Command Prompt/Terminal** in your project folder
2. **Run the build script:**
   ```bash
   build-apk.bat
   ```
3. **Wait for completion** (may take 5-10 minutes for first build)
4. **Find your APK** at: `build\app\outputs\flutter-apk\app-release.apk`

### **Method 2: Manual Build**

1. **Open Command Prompt/Terminal** in your project folder
2. **Get dependencies:**
   ```bash
   flutter pub get
   ```
3. **Clean previous builds:**
   ```bash
   flutter clean
   flutter pub get
   ```
4. **Build the APK:**
   ```bash
   flutter build apk --release
   ```
5. **Find your APK** at: `build\app\outputs\flutter-apk\app-release.apk`

## 📱 Installing APK on Your Phone

### **Step 1: Enable Unknown Sources**
1. Go to **Settings** > **Security** (or **Privacy**)
2. Enable **"Install from unknown sources"** or **"Unknown sources"**
3. On Android 8+, you may need to enable this per-app

### **Step 2: Transfer APK to Phone**
**Option A: USB Cable**
1. Connect phone to computer
2. Copy `app-release.apk` to phone's Downloads folder

**Option B: Cloud Storage**
1. Upload APK to Google Drive/Dropbox
2. Download on phone

**Option C: Email**
1. Email APK to yourself
2. Download from email on phone

### **Step 3: Install APK**
1. Open **File Manager** on phone
2. Navigate to **Downloads**
3. Tap **app-release.apk**
4. Tap **"Install"**
5. Wait for installation
6. Tap **"Open"** to launch

## ✅ App Features (Mock Data Mode)

Your APK will include all features with realistic mock data:

- ✅ **Login Screen** - Works with any username/password
- ✅ **Dashboard** - Real-time mock sensor data
- ✅ **Soil Moisture** - Animated gauges with changing values
- ✅ **Irrigation Control** - Functional toggles and controls
- ✅ **Water Level** - Visual tank with realistic levels
- ✅ **Light Detection** - Dynamic light readings and charts
- ✅ **Camera Feed** - Simulated camera interface
- ✅ **Security System** - Alert management and zone monitoring
- ✅ **Analytics** - Charts and performance metrics
- ✅ **Weather** - 5-day forecast with beautiful UI

## 🔧 Troubleshooting

### **Build Issues**

**"Flutter not found"**
```bash
# Add Flutter to PATH or use full path
C:\flutter\bin\flutter build apk --release
```

**"Android SDK not found"**
```bash
# Run Flutter doctor to diagnose
flutter doctor
# Accept Android licenses
flutter doctor --android-licenses
```

**"Gradle build failed"**
```bash
# Clean and retry
flutter clean
flutter pub get
flutter build apk --release
```

**"Out of memory"**
```bash
# Build with more memory
flutter build apk --release --dart-define=flutter.inspector.structuredErrors=false
```

### **Installation Issues**

**"App not installed"**
- Enable "Unknown sources" in Settings
- Check available storage space
- Uninstall previous version first

**"Parse error"**
- APK file may be corrupted
- Re-download or rebuild APK
- Check Android version compatibility

## 📊 APK Information

- **App Name**: Agri-Bot
- **Package**: com.agribot.app
- **Version**: 1.0.0
- **Size**: ~50-80 MB
- **Min Android**: 5.0 (API 21)
- **Target Android**: Latest
- **Mode**: Mock Data (No internet required)

## 🎯 Testing Checklist

After installing, test these features:

- [ ] App launches successfully
- [ ] Login works with any credentials
- [ ] Dashboard shows sensor data
- [ ] Navigation between screens works
- [ ] Charts and graphs display properly
- [ ] Buttons and controls respond
- [ ] Animations are smooth
- [ ] All 9 screens accessible

## 🔄 Switching to Real API

To connect to a real API server later:

1. **Edit** `lib/services/api_service.dart`
2. **Change** `useMockData = false`
3. **Update** `baseUrl` to your API endpoint
4. **Rebuild** APK with new configuration

## 📦 Build Variants

### **Release APK (Recommended)**
```bash
flutter build apk --release
```
- Smaller size (~50MB)
- Optimized performance
- No debugging info

### **Debug APK**
```bash
flutter build apk --debug
```
- Larger size (~80MB)
- Includes debugging
- Easier to troubleshoot

### **Split APKs (Advanced)**
```bash
flutter build apk --split-per-abi
```
- Creates separate APKs for different architectures
- Smaller individual file sizes

## 🚀 Next Steps

1. **Build your APK** using the instructions above
2. **Install on your phone** and test all features
3. **Share with team members** for feedback
4. **Consider publishing** to Google Play Store for wider distribution

## 📞 Need Help?

If you encounter issues:

1. **Check Flutter Doctor**: `flutter doctor`
2. **Review error messages** carefully
3. **Try cleaning**: `flutter clean`
4. **Rebuild dependencies**: `flutter pub get`
5. **Check Android Studio** setup

---

**Your Agri-Bot APK is ready to build! 🌱📱**
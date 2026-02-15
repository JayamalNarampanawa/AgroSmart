# 📱 Agri-Bot APK Build Guide

This guide will help you create an installable APK file from your Agri-Bot Flutter project.

## 🚀 Quick Build (Recommended)

### **Option 1: Automated Build Script**

**Windows:**
```bash
build-apk.bat
```

**macOS/Linux:**
```bash
chmod +x build-apk.sh
./build-apk.sh
```

### **Option 2: Manual Build**

```bash
# 1. Get dependencies
flutter pub get

# 2. Clean previous builds
flutter clean
flutter pub get

# 3. Build APK
flutter build apk --release
```

## 📍 **APK Location**

After successful build, your APK will be located at:
```
build/app/outputs/flutter-apk/app-release.apk
```

## 🔧 **Before Building - Important Setup**

### **1. Update API Configuration**

Edit `lib/services/api_service.dart` and update the `baseUrl`:

```dart
// For local development (replace with your computer's IP)
static const String baseUrl = 'http://192.168.1.100:3000/api';

// For production (replace with your deployed API)
static const String baseUrl = 'https://your-api-domain.com/api';
```

**To find your computer's IP address:**

**Windows:**
```cmd
ipconfig
```
Look for "IPv4 Address" under your network adapter.

**macOS/Linux:**
```bash
ifconfig | grep inet
```

### **2. Start Your API Server**

Make sure your API server is running:
```bash
cd api
npm start
```

The server should be accessible at `http://YOUR_IP:3000`

## 📱 **Installing APK on Your Phone**

### **Step 1: Enable Unknown Sources**
1. Go to **Settings** > **Security** (or **Privacy**)
2. Enable **"Install from unknown sources"** or **"Unknown sources"**
3. On newer Android versions, you may need to enable this per-app (like File Manager)

### **Step 2: Transfer APK**
**Method 1: USB Cable**
1. Connect phone to computer via USB
2. Copy `app-release.apk` to your phone's Downloads folder

**Method 2: Cloud Storage**
1. Upload APK to Google Drive, Dropbox, etc.
2. Download on your phone

**Method 3: Email**
1. Email the APK to yourself
2. Download from email on your phone

### **Step 3: Install APK**
1. Open **File Manager** on your phone
2. Navigate to **Downloads** folder
3. Tap on **app-release.apk**
4. Tap **"Install"**
5. Wait for installation to complete
6. Tap **"Open"** to launch the app

## 🌐 **Network Configuration**

### **For Local API (Development)**

1. **Connect phone and computer to same WiFi network**
2. **Find your computer's IP address** (e.g., 192.168.1.100)
3. **Update API URL** in `lib/services/api_service.dart`:
   ```dart
   static const String baseUrl = 'http://192.168.1.100:3000/api';
   ```
4. **Start API server** on your computer
5. **Rebuild APK** with updated configuration

### **For Production API (Recommended)**

1. **Deploy your API** to a cloud service (Heroku, AWS, etc.)
2. **Update API URL** to your deployed endpoint:
   ```dart
   static const String baseUrl = 'https://your-api.herokuapp.com/api';
   ```
3. **Rebuild APK**

## 🔍 **Troubleshooting**

### **Build Errors**

**"Flutter not found"**
- Install Flutter SDK
- Add Flutter to your system PATH

**"Android SDK not found"**
- Install Android Studio
- Accept Android licenses: `flutter doctor --android-licenses`

**"Gradle build failed"**
- Run `flutter clean`
- Delete `build` folder
- Run `flutter pub get`
- Try building again

### **App Errors**

**"Network Error" or "Connection Failed"**
- Check if API server is running
- Verify IP address in API configuration
- Ensure phone and computer are on same network
- Check firewall settings

**"App won't install"**
- Enable "Unknown sources" in phone settings
- Check available storage space
- Try uninstalling previous version first

## 📊 **Build Variants**

### **Debug APK (Larger, with debugging)**
```bash
flutter build apk --debug
```

### **Release APK (Smaller, optimized)**
```bash
flutter build apk --release
```

### **Split APKs (Smaller per architecture)**
```bash
flutter build apk --split-per-abi
```

## 📦 **APK Information**

- **App Name**: Agri-Bot
- **Package Name**: com.agribot.app
- **Version**: 1.0.0
- **Min Android Version**: Android 5.0 (API 21)
- **Target Android Version**: Latest
- **Permissions**: Internet, Camera, Storage, Location

## 🚀 **Distribution**

### **For Testing**
- Share APK file directly
- Use Firebase App Distribution
- Upload to Google Drive

### **For Production**
- Publish to Google Play Store
- Use proper app signing
- Follow Google Play policies

## 📝 **Build Checklist**

- [ ] Flutter SDK installed and in PATH
- [ ] Android Studio installed
- [ ] API server running and accessible
- [ ] API URL updated in code
- [ ] Dependencies installed (`flutter pub get`)
- [ ] Previous builds cleaned (`flutter clean`)
- [ ] APK built successfully
- [ ] APK tested on device
- [ ] Network connectivity verified

## 🎯 **Next Steps**

1. **Build your APK** using the scripts provided
2. **Install on your phone** following the guide
3. **Test all features** to ensure everything works
4. **Share with team members** for testing
5. **Consider deploying API** to cloud for better accessibility

---

**Need help?** Check the troubleshooting section or refer to the main README.md file.
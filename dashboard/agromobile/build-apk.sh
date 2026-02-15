#!/bin/bash

echo "========================================"
echo "    Agri-Bot APK Builder"
echo "========================================"
echo

echo "[1/5] Checking Flutter installation..."
flutter --version
if [ $? -ne 0 ]; then
    echo "Error: Flutter is not installed or not in PATH"
    echo "Please install Flutter SDK first"
    exit 1
fi

echo
echo "[2/5] Getting Flutter dependencies..."
flutter pub get
if [ $? -ne 0 ]; then
    echo "Error: Failed to get dependencies"
    exit 1
fi

echo
echo "[3/5] Cleaning previous builds..."
flutter clean
flutter pub get

echo
echo "[4/5] Building APK (this may take several minutes)..."
flutter build apk --release
if [ $? -ne 0 ]; then
    echo "Error: Failed to build APK"
    exit 1
fi

echo
echo "[5/5] Build complete!"
echo
echo "========================================"
echo "    APK Location:"
echo "========================================"
echo
echo "build/app/outputs/flutter-apk/app-release.apk"
echo
echo "File size:"
ls -lh build/app/outputs/flutter-apk/app-release.apk | awk '{print $5}'
echo
echo "You can now install this APK on your Android device!"
echo
echo "========================================"
echo "    Installation Instructions:"
echo "========================================"
echo
echo "1. Copy the APK file to your phone"
echo "2. Enable 'Install from unknown sources' in Settings"
echo "3. Tap the APK file to install"
echo "4. Make sure your API server is running on your computer"
echo "5. Update the IP address in lib/services/api_service.dart if needed"
echo
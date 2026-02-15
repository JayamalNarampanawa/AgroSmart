@echo off
echo ========================================
echo    Agri-Bot APK Builder
echo ========================================
echo.

echo [1/5] Checking Flutter installation...
flutter --version
if errorlevel 1 (
    echo Error: Flutter is not installed or not in PATH
    echo Please install Flutter SDK first
    pause
    exit /b 1
)

echo.
echo [2/5] Getting Flutter dependencies...
flutter pub get
if errorlevel 1 (
    echo Error: Failed to get dependencies
    pause
    exit /b 1
)

echo.
echo [3/5] Cleaning previous builds...
flutter clean
flutter pub get

echo.
echo [4/5] Building APK (this may take several minutes)...
flutter build apk --release
if errorlevel 1 (
    echo Error: Failed to build APK
    pause
    exit /b 1
)

echo.
echo [5/5] Build complete!
echo.
echo ========================================
echo    APK Location:
echo ========================================
echo.
echo build\app\outputs\flutter-apk\app-release.apk
echo.
echo File size:
for %%A in (build\app\outputs\flutter-apk\app-release.apk) do echo %%~zA bytes
echo.
echo You can now install this APK on your Android device!
echo.
echo ========================================
echo    Installation Instructions:
echo ========================================
echo.
echo 1. Copy the APK file to your phone
echo 2. Enable "Install from unknown sources" in Settings
echo 3. Tap the APK file to install
echo 4. Make sure your API server is running on your computer
echo 5. Update the IP address in lib/services/api_service.dart if needed
echo.
pause
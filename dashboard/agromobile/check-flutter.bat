@echo off
echo ========================================
echo    Flutter Installation Checker
echo ========================================
echo.

echo Checking if Flutter is installed...
flutter --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Flutter is NOT installed or not in PATH
    echo.
    echo ========================================
    echo    How to Install Flutter:
    echo ========================================
    echo.
    echo 1. Download Flutter SDK from:
    echo    https://flutter.dev/docs/get-started/install/windows
    echo.
    echo 2. Extract to C:\flutter
    echo.
    echo 3. Add to PATH:
    echo    - Open System Properties ^> Environment Variables
    echo    - Add C:\flutter\bin to PATH
    echo.
    echo 4. Install Android Studio:
    echo    https://developer.android.com/studio
    echo.
    echo 5. Run: flutter doctor
    echo.
    echo 6. Accept Android licenses:
    echo    flutter doctor --android-licenses
    echo.
    echo After installation, run build-apk.bat to create your APK
    echo.
) else (
    echo ✅ Flutter is installed!
    echo.
    flutter --version
    echo.
    echo ========================================
    echo    Ready to Build APK!
    echo ========================================
    echo.
    echo Run: build-apk.bat
    echo.
    echo Your APK will be created at:
    echo build\app\outputs\flutter-apk\app-release.apk
    echo.
)

echo ========================================
pause
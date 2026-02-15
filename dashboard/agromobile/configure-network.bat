@echo off
echo ========================================
echo    Agri-Bot Network Configuration
echo ========================================
echo.

echo Finding your computer's IP address...
echo.

for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4 Address"') do (
    set IP=%%a
    set IP=!IP: =!
    echo Your IP Address: !IP!
)

echo.
echo ========================================
echo    Configuration Steps:
echo ========================================
echo.
echo 1. Your computer's IP address is shown above
echo 2. Open lib/services/api_service.dart
echo 3. Replace the baseUrl with:
echo    static const String baseUrl = 'http://YOUR_IP:3000/api';
echo.
echo 4. Make sure your API server is running:
echo    cd api
echo    npm start
echo.
echo 5. Rebuild your APK:
echo    flutter build apk --release
echo.
echo 6. Install the new APK on your phone
echo.
echo ========================================
echo    Firewall Note:
echo ========================================
echo.
echo If the app can't connect to your API:
echo 1. Check Windows Firewall settings
echo 2. Allow Node.js through firewall
echo 3. Or temporarily disable firewall for testing
echo.
pause
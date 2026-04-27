@echo off
REM AgroSmart ML API Setup Script for Windows
REM This script will help you set up and run the ML API server

title AgroSmart ML API Setup
color 0A

cls
echo.
echo ============================================
echo AgroSmart ML API Setup Script
echo ============================================
echo.
echo This script will:
echo 1. Check Python installation
echo 2. Install required packages
echo 3. Start the ML API server
echo.
pause

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo.
    echo [ERROR] Python is not installed or not in PATH
    echo Please install Python from https://www.python.org
    echo Make sure to check "Add Python to PATH" during installation
    pause
    exit /b 1
)

echo [OK] Python found:
python --version
echo.

REM Navigate to ML directory
cd /d "%~dp0"
echo [OK] Changed to ML directory: %cd%

REM Check if model files exist
if not exist "agrosmart_rf_crop_model.pkl" (
    echo [ERROR] Model file not found: agrosmart_rf_crop_model.pkl
    pause
    exit /b 1
)

if not exist "agrosmart_label_encoder.pkl" (
    echo [ERROR] Model file not found: agrosmart_label_encoder.pkl
    pause
    exit /b 1
)

if not exist "agrosmart_feature_order.pkl" (
    echo [ERROR] Model file not found: agrosmart_feature_order.pkl
    pause
    exit /b 1
)

echo [OK] All model files found
echo.

REM Install required packages
echo Installing required Python packages...
echo This may take a few minutes on first run...
echo.

python -m pip install --upgrade pip --quiet
python -m pip install fastapi uvicorn joblib pandas python-multipart --quiet

if errorlevel 1 (
    echo [ERROR] Failed to install packages
    pause
    exit /b 1
)

echo [OK] All packages installed successfully
echo.

REM Start the API server
echo ============================================
echo Starting ML API Server...
echo ============================================
echo.
echo The API will be available at:
echo   http://localhost:8000
echo.
echo In your Flutter app, use:
echo   MLPredictionService.setBaseUrl('http://localhost:8000');
echo.
echo For Android Emulator, use:
echo   http://10.0.2.2:8000
echo.
echo For Physical Device (same WiFi), find your IP:
echo   Open Command Prompt and run: ipconfig | findstr IPv4
echo   Then use: http://YOUR_IP:8000
echo.
echo ============================================
echo.
echo Press Ctrl+C to stop the server
echo.

python -m uvicorn ml_api:app --reload --host 0.0.0.0 --port 8000

pause

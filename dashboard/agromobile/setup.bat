@echo off
echo ========================================
echo    Agri-Bot Setup Script
echo ========================================
echo.

echo [1/4] Setting up API server...
cd api
if not exist node_modules (
    echo Installing Node.js dependencies...
    npm install
    if errorlevel 1 (
        echo Error: Failed to install Node.js dependencies
        echo Please make sure Node.js is installed
        pause
        exit /b 1
    )
) else (
    echo Node.js dependencies already installed
)

echo.
echo [2/4] Setting up Flutter dependencies...
cd ..
flutter pub get
if errorlevel 1 (
    echo Error: Failed to install Flutter dependencies
    echo Please make sure Flutter is installed and in PATH
    pause
    exit /b 1
)

echo.
echo [3/4] Creating environment file...
if not exist api\.env (
    echo PORT=3000 > api\.env
    echo NODE_ENV=development >> api\.env
    echo Environment file created
) else (
    echo Environment file already exists
)

echo.
echo [4/4] Setup complete!
echo.
echo ========================================
echo    How to run the application:
echo ========================================
echo.
echo 1. Start the API server:
echo    cd api
echo    npm start
echo.
echo 2. In a new terminal, run the Flutter app:
echo    flutter run
echo.
echo The API will be available at: http://localhost:3000
echo.
echo ========================================
pause
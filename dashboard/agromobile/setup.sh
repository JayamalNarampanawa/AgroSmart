#!/bin/bash

echo "========================================"
echo "    Agri-Bot Setup Script"
echo "========================================"
echo

echo "[1/4] Setting up API server..."
cd api
if [ ! -d "node_modules" ]; then
    echo "Installing Node.js dependencies..."
    npm install
    if [ $? -ne 0 ]; then
        echo "Error: Failed to install Node.js dependencies"
        echo "Please make sure Node.js is installed"
        exit 1
    fi
else
    echo "Node.js dependencies already installed"
fi

echo
echo "[2/4] Setting up Flutter dependencies..."
cd ..
flutter pub get
if [ $? -ne 0 ]; then
    echo "Error: Failed to install Flutter dependencies"
    echo "Please make sure Flutter is installed and in PATH"
    exit 1
fi

echo
echo "[3/4] Creating environment file..."
if [ ! -f "api/.env" ]; then
    cat > api/.env << EOF
PORT=3000
NODE_ENV=development
EOF
    echo "Environment file created"
else
    echo "Environment file already exists"
fi

echo
echo "[4/4] Setup complete!"
echo
echo "========================================"
echo "    How to run the application:"
echo "========================================"
echo
echo "1. Start the API server:"
echo "   cd api"
echo "   npm start"
echo
echo "2. In a new terminal, run the Flutter app:"
echo "   flutter run"
echo
echo "The API will be available at: http://localhost:3000"
echo
echo "========================================"
#!/bin/bash

# AgroSmart ML API Setup Script for Mac/Linux
# This script will help you set up and run the ML API server

echo ""
echo "============================================"
echo "AgroSmart ML API Setup Script"
echo "============================================"
echo ""
echo "This script will:"
echo "1. Check Python installation"
echo "2. Install required packages"
echo "3. Start the ML API server"
echo ""
read -p "Press Enter to continue..."

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo ""
    echo "[ERROR] Python 3 is not installed"
    echo "Please install Python 3 from https://www.python.org"
    exit 1
fi

echo "[OK] Python found:"
python3 --version
echo ""

# Navigate to ML directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"
echo "[OK] Changed to ML directory: $(pwd)"

# Check if model files exist
if [ ! -f "agrosmart_rf_crop_model.pkl" ]; then
    echo "[ERROR] Model file not found: agrosmart_rf_crop_model.pkl"
    exit 1
fi

if [ ! -f "agrosmart_label_encoder.pkl" ]; then
    echo "[ERROR] Model file not found: agrosmart_label_encoder.pkl"
    exit 1
fi

if [ ! -f "agrosmart_feature_order.pkl" ]; then
    echo "[ERROR] Model file not found: agrosmart_feature_order.pkl"
    exit 1
fi

echo "[OK] All model files found"
echo ""

# Install required packages
echo "Installing required Python packages..."
echo "This may take a few minutes on first run..."
echo ""

python3 -m pip install --upgrade pip --quiet
python3 -m pip install fastapi uvicorn joblib pandas python-multipart --quiet

if [ $? -ne 0 ]; then
    echo "[ERROR] Failed to install packages"
    exit 1
fi

echo "[OK] All packages installed successfully"
echo ""

# Start the API server
echo "============================================"
echo "Starting ML API Server..."
echo "============================================"
echo ""
echo "The API will be available at:"
echo "  http://localhost:8000"
echo ""
echo "In your Flutter app, use:"
echo "  MLPredictionService.setBaseUrl('http://localhost:8000');"
echo ""
echo "For Device on Same WiFi, find your IP:"
echo "  Run: ipconfig getifaddr en0  (on Mac)"
echo "  Or: hostname -I  (on Linux)"
echo "  Then use: http://YOUR_IP:8000"
echo ""
echo "============================================"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

python3 -m uvicorn ml_api:app --reload --host 0.0.0.0 --port 8000

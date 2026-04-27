# Run Commands

Run these from `dashboard/agromobile` unless a command changes folders.

## First Time Setup

```powershell
flutter doctor
flutter pub get
python -m pip install -r ml\api\requirements.txt
```

## Main Flutter App

```powershell
flutter devices
flutter run
```

For Android emulator with both local ML services:

```powershell
flutter run --dart-define=SALES_FORECAST_API_BASE_URL=http://10.0.2.2:8001 --dart-define=ML_CROP_API_BASE_URL=http://10.0.2.2:8766
```

For a physical phone, replace `10.0.2.2` with your computer IP address.

## Sales Forecast FastAPI Service

Train once if needed:

```powershell
python ml\training\train_sales_lstm.py
```

Run:

```powershell
cd ml\api
python -m uvicorn main:app --host 0.0.0.0 --port 8001 --reload
```

Health check:

```powershell
curl http://127.0.0.1:8001/health
```

## Crop ML API Service

Train once if needed:

```powershell
python ml\training\train_crop_mlp.py
```

Run:

```powershell
cd ml\crop_api
python -m uvicorn main:app --host 0.0.0.0 --port 8766 --reload
```

Health check:

```powershell
curl http://127.0.0.1:8766/health
```

## One Command For The Emulator

After both APIs are running:

```powershell
flutter run --dart-define=SALES_FORECAST_API_BASE_URL=http://10.0.2.2:8001 --dart-define=ML_CROP_API_BASE_URL=http://10.0.2.2:8766
```

## Build APK

```powershell
flutter clean
flutter pub get
flutter build apk --release
```

APK output:

```text
build\app\outputs\flutter-apk\app-release.apk
```

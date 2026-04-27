# Crop Prediction Setup

This backend serves the existing `ML Crop Prediction` screen in Flutter.

## Files

- Trainer: `ml/training/train_crop_mlp.py`
- API: `ml/crop_api/main.py`
- Run script: `ml/crop_api/run_api.bat`

## Train The Model

```powershell
cd C:\Users\Mihiranga Rathnayake\Documents\GitHub\AgroSmart\dashboard\agromobile
python -m pip install -r ml\api\requirements.txt
python ml\training\train_crop_mlp.py
```

Generated artifacts:

- `ml/models/crop_mlp.keras`
- `ml/models/crop_mlp_metadata.json`

## Run The Crop API

```powershell
cd C:\Users\Mihiranga Rathnayake\Documents\GitHub\AgroSmart\dashboard\agromobile\ml\crop_api
python -m uvicorn main:app --host 0.0.0.0 --port 8766 --reload
```

Health check:

```powershell
curl http://127.0.0.1:8766/health
```

## Flutter Command For Android Emulator

```powershell
flutter run --dart-define=ML_CROP_API_BASE_URL=http://10.0.2.2:8766
```

Or with both ML backends:

```powershell
flutter run --dart-define=SALES_FORECAST_API_BASE_URL=http://10.0.2.2:8001 --dart-define=ML_CROP_API_BASE_URL=http://10.0.2.2:8766
```

## What The Crop Model Is

- It is a feed-forward neural network, not an LSTM.
- Inputs: `N`, `P`, `K`, `temperature`, `humidity`, `rainfall`, `ph`
- Output: probabilities across crop classes
- Response fields match Flutter exactly:
  - `predictedCrop`
  - `confidence`
  - `probabilities`

## Viva Notes

- We used an MLP because crop prediction here is tabular classification, not time-series forecasting.
- The model is trained on a starter synthetic dataset generated from agronomic crop ranges bundled in the trainer.
- The backend normalizes features using saved mean and standard deviation from training metadata.

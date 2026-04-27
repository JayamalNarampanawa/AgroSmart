# Sales Forecasting Setup

This module now supports two backend paths:

- `LSTM sales forecaster` as the primary deep learning backend
- `Random Forest sales forecaster` as the legacy fallback baseline

The Flutter app still calls the same API contract, so no mobile-side change is required.

## Files That Matter

- Flutter screen: `lib/screens/sales_forecast_screen.dart`
- Dart models: `lib/models/sales_forecast.dart`
- API client: `lib/services/sales_forecast_api_service.dart`
- FastAPI backend: `ml/api/main.py`
- Legacy baseline trainer: `ml/training/train_sales_model.py`
- New deep learning trainer: `ml/training/train_sales_lstm.py`

## How The Backend Chooses A Model

`ml/api/main.py` loads models in this order:

1. `ml/models/sales_lstm.keras` + `ml/models/sales_lstm_metadata.json` + `ml/models/sales_history.csv`
2. `ml/models/tuned_model.pkl` + `ml/models/preprocessor.pkl`
3. Demo seasonal baseline

That means the API will automatically use the LSTM once its artifacts exist.

## Train The LSTM Model

From the repo root:

```powershell
cd C:\Users\Mihiranga Rathnayake\Documents\GitHub\AgroSmart\dashboard\agromobile
python -m pip install -r ml\api\requirements.txt
python ml\training\train_sales_lstm.py
```

Generated LSTM artifacts:

- `ml/models/sales_lstm.keras`
- `ml/models/sales_lstm_metadata.json`
- `ml/models/sales_history.csv`

The trainer:

- normalizes the dataset columns
- creates time-series windows with `lookback=14`
- trains an `LSTM -> Dropout -> LSTM -> Dense` network
- evaluates on a chronological test split
- saves model metrics and residual spread for confidence intervals

## Optional Baseline Trainer

If you want a classical ML baseline for comparison:

```powershell
python ml\training\train_sales_model.py
```

Generated baseline artifacts:

- `ml/models/tuned_model.pkl`
- `ml/models/preprocessor.pkl`
- `ml/models/model_metadata.json`

## Run The FastAPI Backend

```powershell
cd C:\Users\Mihiranga Rathnayake\Documents\GitHub\AgroSmart\dashboard\agromobile\ml\api
python -m uvicorn main:app --host 0.0.0.0 --port 8001 --reload
```

Health check:

```powershell
curl http://127.0.0.1:8001/health
```

Expected health fields:

- `active_model`
- `lstm_loaded`
- `legacy_model_loaded`
- `tensorflow_available`

If `active_model` is `lstm`, the deep learning path is live.

## Run The Flutter App

Android emulator:

```powershell
flutter run
```

Physical phone:

```powershell
flutter run --dart-define=SALES_FORECAST_API_BASE_URL=http://YOUR-PC-IP:8001
```

## API Contract

`POST /predict`

```json
{
  "start_date": "2026-04-16",
  "end_date": "2026-04-30",
  "product_category": "Grocery",
  "region": "North",
  "store": "Store A",
  "promo_flag": true
}
```

Response shape:

```json
{
  "total_predicted_sales": 15200.5,
  "average_daily_sales": 1013.36,
  "confidence_low": 13376.44,
  "confidence_high": 17024.56,
  "model_name": "LSTM sales forecaster",
  "is_demo": false,
  "forecast": [
    {
      "date": "2026-04-16",
      "predicted_sales": 1010.12
    }
  ],
  "metrics": {
    "rmse": 120.4,
    "mae": 89.6,
    "mape": 7.1,
    "r2": 0.88
  },
  "note": "LSTM autoregressive forecast using 14 prior sales steps from exact category/region/store history."
}
```

## What The LSTM Is Doing

- The model learns from previous sales values and time features.
- Each training sample is a window of the last 14 sales timesteps.
- Each timestep also includes promo flag, day of week, month, week number, weekend flag, and one-hot encoded category, region, and store.
- At prediction time, the API takes the latest historical window for the requested category/region/store and predicts one day ahead.
- For multi-day forecasts, it feeds each predicted day back into the next window. That is autoregressive forecasting.

## Viva Talking Points

- Why LSTM: It is designed for sequence data and can learn temporal dependencies better than a plain dense model.
- Why keep the API contract stable: Flutter stays simple and the model can be replaced without changing mobile screens.
- Why keep the Random Forest trainer: It gives a non-deep-learning baseline for comparison.
- Why confidence intervals are approximate: They are derived from test residual spread, not Bayesian uncertainty.
- Why the API needs `sales_history.csv`: The LSTM needs prior observed sales to seed the forecast window.

## Next Steps

1. Replace the starter CSV with your approved dataset.
2. Retrain the LSTM.
3. Check `/health` and confirm `active_model=lstm`.
4. Record forecast screenshots from the mobile app for the demo and viva.

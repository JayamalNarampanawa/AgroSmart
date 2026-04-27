# Sales Forecasting Viva Notes

## End-To-End Flow

1. The user opens the Sales Forecast screen in Flutter.
2. Flutter builds a `SalesForecastRequest` in `lib/models/sales_forecast.dart`.
3. `lib/services/sales_forecast_api_service.dart` sends `POST /predict` to the FastAPI backend.
4. `ml/api/main.py` decides which backend is available:
   - LSTM model
   - legacy Random Forest model
   - demo baseline
5. The API returns forecast values, summary metrics, and a note describing the active forecast path.
6. Flutter renders the totals, confidence band, chart, and model label.

## Why We Used LSTM

- Sales data is sequential and depends on previous timesteps.
- LSTM is a recurrent neural network that is good at learning temporal patterns.
- It can learn trend, weekly seasonality, and promo-related effects from historical windows.

## What The LSTM Input Looks Like

Each sample is a sequence of the last `14` timesteps.

For each timestep, the model receives:

- scaled sales
- promo flag
- normalized day of week
- normalized month
- normalized week of year
- weekend flag
- one-hot product category
- one-hot region
- one-hot store

Shape idea:

- batch size: number of samples in one training batch
- timesteps: `14`
- features: numeric features plus one-hot vectors

So the LSTM input is effectively:

`[batch, 14, feature_count]`

## Model Architecture

The network in `ml/training/train_sales_lstm.py` is:

1. `LSTM(64, return_sequences=True)`
2. `Dropout(0.20)`
3. `LSTM(32)`
4. `Dense(16, relu)`
5. `Dense(1)`

Output:

- one predicted sales value for the next timestep

## How Forecasting Works

The LSTM is trained for one-step-ahead prediction.

At inference time:

1. The API loads the latest historical sales window for the requested category, region, and store.
2. It predicts the next day.
3. That predicted value is appended into the sequence.
4. The new sequence is used to predict the following day.
5. This repeats until the requested end date.

This is called autoregressive forecasting.

## Why We Save `sales_history.csv`

The trained `.keras` model alone is not enough.

The API also needs recent historical values to build the initial 14-step window for inference. That is why `sales_history.csv` is saved alongside the model.

## Why We Save `sales_lstm_metadata.json`

The metadata file stores:

- model name
- lookback window size
- feature vocabularies for category, region, and store
- target mean and standard deviation
- evaluation metrics
- residual standard deviation

The API uses that file to:

- scale and unscale sales values correctly
- reconstruct one-hot vectors consistently
- report metrics and confidence intervals

## Confidence Interval Explanation

The API computes confidence bounds from the standard deviation of test residuals.

This means:

- it is an approximate interval
- it is based on empirical model error on held-out data
- it is not a probabilistic guarantee

## Why We Kept The Random Forest

The Random Forest trainer is still useful because:

- it provides a baseline for comparison
- it shows that deep learning was not added blindly
- you can explain why LSTM is more suitable for sequence forecasting

## Good Viva Answers

If asked "Why not use a dense neural network?"

- A plain dense model does not model sequence order as naturally as LSTM for time-series forecasting.

If asked "Why not run the model directly in Flutter?"

- Backend inference is simpler to maintain, easier to update, and avoids shipping model files inside the mobile app.

If asked "What happens if the LSTM model is missing?"

- The backend falls back to the legacy sklearn model, and if that is also missing it uses the demo baseline.

If asked "How do you know the app is really using the LSTM?"

- Call `/health` and confirm `active_model` is `lstm`.
- In prediction responses, `model_name` should be `LSTM sales forecaster`.

If asked "What is the main limitation of this implementation?"

- Multi-day forecasts are autoregressive, so prediction error can accumulate over longer horizons.

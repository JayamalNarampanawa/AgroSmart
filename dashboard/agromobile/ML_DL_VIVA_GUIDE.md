# Machine Learning and Deep Learning Viva Guide

This document explains every ML and DL part of the AgroSmart mobile application in one place so it can be used for viva preparation.

## 1. Short Summary

This application contains three different intelligence paths:

1. Deep learning for sales forecasting
2. Deep learning for crop prediction
3. Rule-based crop recommendation

The important distinction is:

- `Sales forecasting` uses a deep learning `LSTM` model
- `Crop prediction` uses a deep learning `MLP` model
- `Farm profile crop recommendation` is not deep learning; it is local rule/scoring logic

So if an examiner asks whether the app uses deep learning, the correct answer is:

- `Yes, the app uses deep learning in two places: sales forecasting and crop prediction.`

If they ask whether all recommendations in the app are deep learning, the correct answer is:

- `No. Some features use deep learning, and some use deterministic rule-based scoring.`

## 2. Where ML and DL Are Used

### A. Sales Forecasting

Purpose:

- Predict future sales for a selected date range, category, region, store, and promo state

Frontend files:

- `lib/screens/sales_forecast_screen.dart`
- `lib/models/sales_forecast.dart`
- `lib/services/sales_forecast_api_service.dart`

Backend files:

- `ml/training/train_sales_lstm.py`
- `ml/training/train_sales_model.py`
- `ml/api/main.py`

Model type:

- Primary model: `LSTM` deep learning model
- Fallback model: `Random Forest` classical ML baseline
- Final fallback: demo seasonal baseline

### B. Crop Prediction

Purpose:

- Predict the most suitable crop from soil and weather features

Frontend files:

- `lib/screens/ml_crop_recommendation_screen.dart`
- `lib/services/ml_prediction_service.dart`
- `lib/screens/crop_details_screen.dart`

Backend files:

- `ml/training/train_crop_mlp.py`
- `ml/crop_api/main.py`

Model type:

- `MLP` feed-forward neural network

### C. Rule-Based Crop Recommendation

Purpose:

- Score crops using known NPK and pH ranges for a farm profile

Frontend/backend location:

- `lib/services/crop_recommendation_service.dart`

Model type:

- No machine learning model
- It is local formula/range-based scoring

This distinction is very important in the viva.

## 3. Difference Between ML and Deep Learning In This App

### Classical ML

Classical ML in this project is the `Random Forest` baseline used for sales forecasting.

Why it matters:

- It gives a baseline to compare against deep learning
- It helps justify why LSTM was chosen for sequence data

### Deep Learning

Deep learning in this project means neural-network-based models:

- `LSTM` for time-series sales forecasting
- `MLP` for crop classification from tabular input data

Why two different DL models were used:

- Sales forecasting is sequential, so LSTM is appropriate
- Crop prediction here is tabular classification, so MLP is appropriate

## 4. Full Application Architecture

The mobile app is Flutter.

The ML/DL inference does not run inside Flutter directly.

Instead:

1. Flutter collects user input
2. Flutter sends HTTP requests to FastAPI services
3. Python backend loads trained model artifacts
4. Backend runs inference
5. Backend returns JSON response
6. Flutter displays the prediction

Why backend inference was used instead of running models directly in Flutter:

- easier to maintain
- easier to replace models
- simpler than shipping TensorFlow Lite immediately
- keeps model code in Python where training and inference logic are easier to manage

## 5. Sales Forecasting Deep Learning Path

## 5.1 What Problem It Solves

It predicts future sales over a date range based on:

- start date
- end date
- product category
- region
- store
- promo flag

## 5.2 Why LSTM Was Chosen

LSTM is suitable because sales data is time-series data.

It can learn:

- trend
- seasonality
- weekly patterns
- promo effects
- dependence on previous sales values

If asked "Why not use an MLP for sales forecasting?", answer:

- `Because sales forecasting depends on ordered historical timesteps, and LSTM captures temporal dependence better than a plain feed-forward network.`

## 5.3 Input Features For Sales LSTM

Each sequence window uses the previous `14` timesteps.

For each timestep, the model receives:

- scaled sales
- promo flag
- normalized day of week
- normalized month
- normalized week of year
- weekend flag
- one-hot encoded category
- one-hot encoded region
- one-hot encoded store

Input shape idea:

- `[batch_size, 14, feature_count]`

## 5.4 Sales LSTM Architecture

The architecture in `ml/training/train_sales_lstm.py` is:

1. `LSTM(64, return_sequences=True)`
2. `Dropout(0.20)`
3. `LSTM(32)`
4. `Dense(16, activation="relu")`
5. `Dense(1)`

Output:

- next-step sales value

## 5.5 How Multi-Day Forecasting Works

The model is trained for one-step-ahead prediction.

At inference time:

1. backend loads the most recent historical sales window
2. predicts the next day
3. appends that predicted value to the sequence
4. uses the updated sequence to predict the next day again
5. repeats until the end date

This is called `autoregressive forecasting`.

Important viva point:

- `The longer the forecast horizon, the more error can accumulate because each later prediction depends on previous predicted values.`

## 5.6 Sales Artifacts Saved

Primary deep learning artifacts:

- `ml/models/sales_lstm.keras`
- `ml/models/sales_lstm_metadata.json`
- `ml/models/sales_history.csv`

Legacy baseline artifacts:

- `ml/models/tuned_model.pkl`
- `ml/models/preprocessor.pkl`
- `ml/models/model_metadata.json`

Why `sales_history.csv` is needed:

- the model needs previous real sales values to seed the initial 14-step input window

Why metadata is needed:

- stores feature vocabulary
- stores scaling values
- stores metrics
- stores residual spread for confidence bounds

## 5.7 Sales API Behavior

File:

- `ml/api/main.py`

The backend chooses models in this order:

1. LSTM model
2. legacy Random Forest model
3. demo baseline

So the app still works even if the deep learning artifacts are unavailable.

Health endpoint:

- `GET /health`

Prediction endpoint:

- `POST /predict`

Important health field:

- `active_model`

Possible values:

- `lstm`
- `legacy_sklearn`
- `demo`

How to prove in viva that the app is using deep learning:

- Call `/health` and show `active_model = lstm`
- Show prediction response `model_name = LSTM sales forecaster`

## 5.8 Confidence Interval Explanation

The sales API returns:

- `confidence_low`
- `confidence_high`

These are computed from held-out test residual spread.

This means:

- it is an approximate confidence band
- it is based on model error observed on test data
- it is not a formal probabilistic guarantee

## 6. Crop Prediction Deep Learning Path

## 6.1 What Problem It Solves

It predicts the most suitable crop from these inputs:

- `N`
- `P`
- `K`
- `temperature`
- `humidity`
- `rainfall`
- `ph`

This is a `classification` problem, not forecasting.

## 6.2 Why MLP Was Chosen

The crop inputs are tabular values, not sequences.

So a feed-forward neural network is more appropriate than LSTM.

If asked "Why not use LSTM for crop prediction?", answer:

- `Because crop prediction here is based on one input vector of soil and climate features, not an ordered time sequence.`

## 6.3 Crop MLP Architecture

The architecture in `ml/training/train_crop_mlp.py` is:

1. `Dense(64, relu)`
2. `Dropout(0.20)`
3. `Dense(32, relu)`
4. `Dense(class_count, softmax)`

Output:

- class probabilities for crops

## 6.4 Crop Dataset

The current crop trainer builds a `starter synthetic dataset`.

Why:

- it allows the feature to run end-to-end locally
- it reflects agronomic ranges already used in the application
- it provides a working deep learning demo without depending on an external dataset first

The generated CSV is:

- `ml/data/raw/starter_crop_dataset.csv`

Important viva answer:

- `The current implementation uses a starter synthetic dataset derived from known agronomic ranges. In a production or research-grade system, this should be replaced with a real labeled agricultural dataset.`

That is a strong and honest answer.

## 6.5 Crop Artifacts Saved

- `ml/models/crop_mlp.keras`
- `ml/models/crop_mlp_metadata.json`

Metadata stores:

- feature names
- class labels
- label mapping
- feature mean
- feature standard deviation
- evaluation metrics

## 6.6 Crop API Behavior

File:

- `ml/crop_api/main.py`

Health endpoint:

- `GET /health`

Prediction endpoint:

- `POST /predict`

Request fields:

- `N`
- `P`
- `K`
- `temperature`
- `humidity`
- `rainfall`
- `ph`

Response fields:

- `predictedCrop`
- `confidence`
- `probabilities`

How prediction works:

1. API receives input JSON
2. input is normalized using saved means and standard deviations
3. MLP runs inference
4. API returns all class probabilities and top predicted crop

## 7. Rule-Based Crop Recommendation Path

The farm profile recommendation screen is not the same as the MLP crop prediction screen.

It uses:

- manually defined crop ideal ranges
- formula-based fit scoring
- confidence labels derived from score thresholds

This logic exists in:

- `lib/services/crop_recommendation_service.dart`

Why this matters in viva:

- if asked "Is every crop recommendation AI-based?", the answer is `No`
- one part is deep learning classification
- another part is deterministic agronomic scoring

That shows you understand the system clearly.

## 8. Mobile To Backend Data Flow

## 8.1 Sales Flow

1. user opens the sales forecast screen
2. Flutter builds a `SalesForecastRequest`
3. `lib/services/sales_forecast_api_service.dart` sends `POST /predict`
4. sales FastAPI backend chooses `lstm`, `legacy_sklearn`, or `demo`
5. backend returns JSON
6. app displays chart, totals, confidence range, and metrics

If the backend is unavailable:

- the app falls back to demo data
- the response note says FastAPI was unavailable

## 8.2 Crop Flow

1. user opens the ML crop prediction screen
2. user enters NPK, temperature, humidity, rainfall, and pH
3. `lib/services/ml_prediction_service.dart` sends `POST /predict`
4. crop FastAPI backend runs MLP inference
5. backend returns predicted crop, confidence, and probabilities
6. app displays the recommendation and crop details

## 9. Commands To Run Everything

Run these from:

- `c:\Users\Mihiranga Rathnayake\Documents\GitHub\AgroSmart\dashboard\agromobile`

## 9.1 Install Python Dependencies

```powershell
python -m pip install -r ml\api\requirements.txt
```

## 9.2 Train Sales Model

```powershell
python ml\training\train_sales_lstm.py
```

## 9.3 Train Crop Model

```powershell
python ml\training\train_crop_mlp.py
```

## 9.4 Run Sales API

```powershell
cd ml\api
python -m uvicorn main:app --host 0.0.0.0 --port 8001 --reload
```

## 9.5 Run Crop API

Default crop port in code is `8766`, but on your machine `8766` was occupied.

So your current working command is:

```powershell
cd ml\crop_api
python -m uvicorn main:app --host 0.0.0.0 --port 8767 --reload
```

## 9.6 Health Checks

Sales:

```powershell
curl http://127.0.0.1:8001/health
```

Crop:

```powershell
curl http://127.0.0.1:8767/health
```

## 9.7 Run Flutter App With Both APIs

For Android emulator:

```powershell
flutter run --dart-define=SALES_FORECAST_API_BASE_URL=http://10.0.2.2:8001 --dart-define=ML_CROP_API_BASE_URL=http://10.0.2.2:8767
```

Why `10.0.2.2`:

- Android emulator uses `10.0.2.2` to reach the PC's localhost

## 10. What To Say If Something Fails

If sales screen shows demo baseline:

- sales API was not reachable
- or trained artifacts were not loaded

If crop screen shows connection error:

- crop API was not running
- wrong port was used
- Flutter define was not passed correctly

If sales trainer fails on CSV:

- the trainer expects a sales-style CSV with date and sales columns
- in this repo it has been fixed to skip incompatible CSV files automatically

If crop port 8766 fails:

- another local process is using that port
- run crop API on `8767` instead and update the Flutter define

## 11. Main Strengths Of This Implementation

- Uses deep learning where it makes sense
- Keeps mobile app simple by doing inference on backend
- Has fallback behavior so the app still works during failures
- Separates training code from inference code
- Exposes clean HTTP APIs for the Flutter app

## 12. Main Limitations

### Sales Forecasting

- multi-day forecast is autoregressive, so errors can accumulate
- current accuracy depends on training data quality
- confidence interval is approximate

### Crop Prediction

- current training data is synthetic starter data
- a real agricultural labeled dataset would improve realism
- crop classes are currently limited to the classes bundled in the trainer

### Overall System

- backend services must be running for live inference
- app falls back gracefully, but fallback is not the same as real inference

## 13. Strong Viva Questions And Good Answers

### Q1. Where is deep learning used in this application?

Answer:

- `Deep learning is used in the sales forecasting module with an LSTM model and in the crop prediction module with an MLP classifier.`

### Q2. Why did you use LSTM for sales forecasting?

Answer:

- `Because sales forecasting is a time-series problem. LSTM is designed to capture temporal dependencies across sequential historical timesteps.`

### Q3. Why did you use MLP for crop prediction instead of LSTM?

Answer:

- `Because crop prediction in this app is a tabular classification problem based on one feature vector, not a sequence of timesteps.`

### Q4. Is the farm profile crop recommendation also deep learning?

Answer:

- `No. That part is rule-based scoring using predefined agronomic ranges, while the separate ML crop prediction screen uses the deep learning model.`

### Q5. Why are the models served through FastAPI instead of directly inside Flutter?

Answer:

- `Serving through FastAPI keeps training and inference logic in Python, makes model replacement easier, and avoids packaging model execution logic directly into the mobile app.`

### Q6. How does the sales model forecast multiple future days?

Answer:

- `It performs autoregressive forecasting. It predicts one day ahead, appends that prediction to the sequence, and repeats until the requested horizon is complete.`

### Q7. What happens if the LSTM model is missing?

Answer:

- `The API falls back to the legacy Random Forest model, and if that is also unavailable it returns a demo baseline.`

### Q8. How do you know the app is actually using the model?

Answer:

- `For sales, I can call the health endpoint and verify active_model is lstm. For crop prediction, I can verify the crop API health endpoint and observe a live predictedCrop and probabilities response from the model.`

### Q9. What is the biggest limitation of the crop model right now?

Answer:

- `The current version uses a starter synthetic dataset, so it is best viewed as a functional deep learning integration rather than a final production-quality agricultural classifier.`

### Q10. What is the biggest limitation of the sales model right now?

Answer:

- `Multi-step forecasts can accumulate error because each future prediction depends on earlier predicted values.`

## 14. Best Final Viva Summary

If you need one strong closing explanation, say this:

- `This application uses both machine learning and deep learning in a structured way. Sales forecasting uses an LSTM because it is a time-series problem. Crop prediction uses an MLP because it is a tabular classification problem. In addition, the app also contains a rule-based agronomic recommendation module, which is not deep learning. The Flutter frontend communicates with Python FastAPI services for inference, and the system includes fallback behavior, health endpoints, and saved model artifacts for reliable deployment.`

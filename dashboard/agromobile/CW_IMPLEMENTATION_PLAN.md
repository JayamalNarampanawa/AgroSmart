r# HNDSE25.1 Machine Learning Coursework - Implementation Plan

**Coursework:** Sales Forecasting End-to-End ML Project  
**Deadline:** 27th April 2026  
**Total Marks:** 100  
**Submission:** PDF Report + Jupyter Notebook + Mobile App + Presentation Slides

---

## 📋 Project Overview

Build a complete sales forecasting system that demonstrates:

- Understanding of ML pipelines and algorithms
- Real-world data processing and feature engineering
- Model selection, comparison, and hyperparameter tuning
- Integration of at least one deep learning forecasting model
- Deployment in a working mobile application

**Key Constraint:** Use a Kaggle sales dataset approved by lecturer (Phase 1)

---

## 🎯 Phase Breakdown & Marks

| Phase       | Task                | Marks   | Key Deliverables                                                               |
| ----------- | ------------------- | ------- | ------------------------------------------------------------------------------ |
| **Phase 1** | Proposal            | 10      | Problem statement, dataset URL, approach, feasibility, team roles              |
| **Phase 2** | EDA                 | 15      | Statistical summaries, visualizations, temporal analysis, insights report      |
| **Phase 3** | Preprocessing       | 15      | Missing value handling, feature engineering, normalization, pipeline code      |
| **Phase 4** | Model Selection     | 15      | ≥2 algorithms, justification, baseline implementation, comparison table        |
| **Phase 5** | Tuning & Evaluation | 15      | Tuning strategy, actual vs predicted plots, residual analysis, reflection      |
| **Phase 6** | Mobile Application  | 30      | Input screen, results display, historical comparison, live demo, documentation |
| **TOTAL**   |                     | **100** |                                                                                |

---

## 🔧 Technology Stack

### Backend ML Pipeline

- **Language:** Python 3.9+
- **Libraries:**
  - `pandas` - data manipulation
  - `numpy` - numerical operations
  - `matplotlib`, `seaborn` - visualizations
  - `scikit-learn` - preprocessing, models, evaluation
  - `xgboost` or `lightgbm` - gradient boosting models
  - `tensorflow` / `keras` - deep learning models (LSTM/GRU)
  - `joblib` - model serialization

### Model Deployment

- **Framework:** FastAPI
- **Server:** Uvicorn
- **Model Format:** joblib (.pkl) / pickle / TensorFlow SavedModel (.keras)

### Mobile Application

- **Framework:** Flutter / Dart
- **Platform:** Android (APK) + iOS
- **HTTP Client:** Dart `http` package
- **UI:** Material Design 3, responsive layout

---

## 📁 Project Structure

```
sales-forecasting-cw/
├── ml/
│   ├── notebook/
│   │   └── sales_forecasting_pipeline.ipynb          (Phases 2-5)
│   ├── data/
│   │   ├── raw/                                       (Raw Kaggle CSV)
│   │   ├── processed/                                 (After preprocessing)
│   │   └── train_test_split/                          (Time-based splits)
│   ├── models/
│   │   ├── baseline_model.pkl                         (Phase 4)
│   │   ├── tuned_model.pkl                            (Phase 5)
│   │   └── preprocessor.pkl                           (Scaler + encoder)
│   ├── api/
│   │   ├── main.py                                    (FastAPI app)
│   │   ├── requirements.txt
│   │   └── Dockerfile                                 (Optional)
│   └── reports/
│       └── visualizations/                            (Plots from each phase)
├── mobile/
│   ├── flutter_app/                                   (Phase 6 Flutter project)
│   ├── android/
│   └── ios/
├── docs/
│   ├── PROPOSAL.pdf                                   (Phase 1 - 3 pages max)
│   ├── FINAL_REPORT.pdf                               (Phases 2-5 - structured)
│   └── PRESENTATION_SLIDES.pptx
└── README.md                                          (Setup & run instructions)
```

---

## 📝 Phase-by-Phase Implementation Details

### **Phase 1: Project Proposal (10 Marks)**

**Approval Required:** Must get lecturer sign-off before proceeding.

**Deliverables (PDF, max 3 pages):**

1. **Problem Statement** (1 page)
   - What business problem are we solving?
   - Example: "Forecast weekly sales by product category and store region for a retail chain to optimize inventory and staffing."
   - Why is it important?

2. **Dataset Overview** (0.5 page)
   - Kaggle dataset URL
   - File size, number of rows/columns
   - Time span (e.g., Jan 2015 - Dec 2023)
   - Key columns: date, sales (target), store, product, category, region, optional promo flags
   - Why is it suitable?

3. **Proposed Approach** (0.5 page)
   - Which algorithms will we test? (e.g., Linear Regression, Random Forest, XGBoost)
   - Why are they appropriate?
   - Expected challenges and mitigation strategies

4. **Team Roles** (if group)
   - Member 1: EDA + visualization
   - Member 2: Preprocessing pipeline + feature engineering
   - Member 3: Model selection + training
   - Member 4: Tuning + mobile app development

**Evaluation Criteria:**

- Clarity and relevance of problem (4 marks)
- Justification and suitability of dataset (3 marks)
- Feasibility and risk identification (3 marks)

---

### **Phase 2: Exploratory Data Analysis (15 Marks)**

**Objective:** Understand data structure, distributions, and relationships before modeling.

**Deliverables (Jupyter Notebook section):**

1. **Dataset Summary**

   ```python
   df.shape                                    # dimensions
   df.dtypes                                   # column types
   df.describe()                               # stats: mean, std, min, max
   df.isnull().sum()                           # missing values count
   ```

2. **Univariate Analysis**
   - Histogram of sales distribution
   - Box plot for outliers detection
   - KDE plot for skewness assessment

3. **Temporal Analysis** (critical for time series)
   - Time series plot: sales over time
   - Rolling mean/std to detect trends
   - Seasonality decomposition (weekly, monthly patterns)
   - Holiday/anomaly identification

4. **Multivariate Analysis**
   - Correlation heatmap (features vs target)
   - Scatter plots: key features vs sales
   - Box plots: sales by category, by region, by store

5. **Key Insights Report** (1+ page written summary)
   - What drives sales? (Top 3-5 patterns)
   - Seasonality observed?
   - Data quality issues?
   - Recommendations for preprocessing and modeling

**Evaluation Criteria:**

- Completeness of statistical summaries (4 marks)
- Quality and relevance of visualizations (5 marks)
- Actionable insights (4 marks)
- Clarity of written report (2 marks)

---

### **Phase 3: Data Preprocessing Pipeline (15 Marks)**

**Objective:** Build a reusable, reproducible pipeline that prevents data leakage.

**Deliverables (Python class or scikit-learn Pipeline):**

1. **Missing Value Handling**
   - Strategy: drop, forward-fill (time series), or imputation
   - Justification: why this strategy for this column?
   - Code example:
     ```python
     df['sales'].fillna(method='ffill')         # time series forward-fill
     df.dropna(subset=['critical_column'])      # if necessary
     ```

2. **Feature Engineering** (most important for time series forecasting)

   ```python
   # Lag features
   df['sales_lag_1'] = df['sales'].shift(1)
   df['sales_lag_7'] = df['sales'].shift(7)      # weekly lag

   # Rolling averages
   df['rolling_mean_7'] = df['sales'].rolling(7).mean()
   df['rolling_std_7'] = df['sales'].rolling(7).std()

   # Time-based features
   df['day_of_week'] = df['date'].dt.dayofweek
   df['month'] = df['date'].dt.month
   df['week_of_year'] = df['date'].dt.isocalendar().week

   # If available: promo flags, holiday indicators
   ```

3. **Categorical Encoding**

   ```python
   # One-hot encoding for low-cardinality features
   df = pd.get_dummies(df, columns=['category', 'region'])

   # Label encoding for high-cardinality features or if needed
   from sklearn.preprocessing import LabelEncoder
   le = LabelEncoder()
   df['store_encoded'] = le.fit_transform(df['store'])
   ```

4. **Normalization / Standardization**

   ```python
   from sklearn.preprocessing import StandardScaler
   scaler = StandardScaler()
   df[['sales', 'numeric_col']] = scaler.fit_transform(df[['sales', 'numeric_col']])
   ```

5. **Time-Based Train / Validation / Test Split** (NO random split for time series!)

   ```python
   train_size = int(0.7 * len(df))
   val_size = int(0.15 * len(df))

   train = df[:train_size]
   validation = df[train_size:train_size + val_size]
   test = df[train_size + val_size:]

   # CRITICAL: Train on past, validate/test on future
   ```

6. **Pipeline Implementation**

   ```python
   from sklearn.pipeline import Pipeline

   preprocessing_pipeline = Pipeline([
       ('scaler', StandardScaler()),
       ('feature_engineering', CustomFeatureEngineering()),
   ])

   # Save for later use in Phase 5 and Phase 6
   joblib.dump(preprocessing_pipeline, 'models/preprocessor.pkl')
   ```

**Evaluation Criteria:**

- Completeness and correctness of cleaning (4 marks)
- Quality and creativity of feature engineering (5 marks)
- No data leakage in time-based splits (3 marks)
- Code clarity and reusability (3 marks)

---

### **Phase 4: Model Selection & Implementation (15 Marks)**

**Objective:** Train ≥2 algorithms including **at least 1 deep learning model** (e.g., LSTM/GRU), compare baselines, and pick best for tuning.

**Recommended algorithms (pick at least 2):**

| Algorithm         | Pros                                      | Cons                       | When to Use           |
| ----------------- | ----------------------------------------- | -------------------------- | --------------------- |
| Linear Regression | Simple, interpretable, fast               | Assumes linearity          | Baseline              |
| Ridge / Lasso     | Regularization, prevents overfitting      | Linear assumption          | Baseline with penalty |
| Random Forest     | Handles non-linearity, feature importance | Slower, less interpretable | Medium complexity     |
| XGBoost           | SOTA performance, handles missing data    | Requires tuning, black box | Complex problems      |
| LightGBM          | Fast, memory efficient                    | Requires tuning            | Large datasets        |
| Prophet           | Time series specific, seasonal handling   | Requires extra libraries   | Strong seasonality    |
| LSTM / GRU        | Captures temporal dependencies well       | Needs more data/tuning     | Deep learning track   |

**Implementation template:**

```python
from sklearn.linear_model import LinearRegression, Ridge
from sklearn.ensemble import RandomForestRegressor
from xgboost import XGBRegressor
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score

# Model 1: Linear Regression (Baseline)
model_lr = LinearRegression()
model_lr.fit(X_train, y_train)
pred_lr = model_lr.predict(X_val)
rmse_lr = np.sqrt(mean_squared_error(y_val, pred_lr))

# Model 2: Random Forest
model_rf = RandomForestRegressor(n_estimators=100, random_state=42)
model_rf.fit(X_train, y_train)
pred_rf = model_rf.predict(X_val)
rmse_rf = np.sqrt(mean_squared_error(y_val, pred_rf))

# Model 3: XGBoost (optional but recommended)
model_xgb = XGBRegressor(n_estimators=100, learning_rate=0.1, random_state=42)
model_xgb.fit(X_train, y_train)
pred_xgb = model_xgb.predict(X_val)
rmse_xgb = np.sqrt(mean_squared_error(y_val, pred_xgb))

# Comparison Table
results = pd.DataFrame({
    'Model': ['Linear Regression', 'Random Forest', 'XGBoost'],
    'RMSE': [rmse_lr, rmse_rf, rmse_xgb],
    'MAE': [mae_lr, mae_rf, mae_xgb],
    'R²': [r2_lr, r2_rf, r2_xgb]
})
```

**Deep Learning (required) - LSTM baseline template:**

```python
import tensorflow as tf
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import LSTM, Dense, Dropout

# Example sequence shape: (samples, timesteps, features)
model_lstm = Sequential([
   LSTM(64, return_sequences=True, input_shape=(X_train_seq.shape[1], X_train_seq.shape[2])),
   Dropout(0.2),
   LSTM(32),
   Dense(1)
])

model_lstm.compile(optimizer='adam', loss='mse', metrics=['mae'])

history = model_lstm.fit(
   X_train_seq,
   y_train_seq,
   validation_data=(X_val_seq, y_val_seq),
   epochs=30,
   batch_size=32,
   verbose=1
)

pred_lstm = model_lstm.predict(X_val_seq).flatten()
rmse_lstm = np.sqrt(mean_squared_error(y_val_seq, pred_lstm))
mae_lstm = mean_absolute_error(y_val_seq, pred_lstm)
r2_lstm = r2_score(y_val_seq, pred_lstm)
```

**Deliverables:**

1. Algorithm explanation (mathematical intuition)
2. Justification for each algorithm choice (including deep learning suitability)
3. Baseline implementation code
4. Comparison table (RMSE, MAE, R²) with classical ML and deep learning
5. Decision: which model to tune? (Usually pick lowest RMSE or best R²)

**Evaluation Criteria:**

- Depth of algorithm explanation (4 marks)
- Quality of justification (4 marks)
- Correctness of implementation (4 marks)
- Comparison table and analysis (3 marks)

---

### **Phase 5: Hyperparameter Tuning & Evaluation (15 Marks)**

**Objective:** Optimize best model and show measurable improvement.

**Tuning Approach:**

1. **TimeSeriesSplit (prevents data leakage in time series)**

   ```python
   from sklearn.model_selection import TimeSeriesSplit

   tscv = TimeSeriesSplit(n_splits=5)
   for train_idx, val_idx in tscv.split(X_train):
       X_train_fold, X_val_fold = X_train[train_idx], X_train[val_idx]
       y_train_fold, y_val_fold = y_train[train_idx], y_train[val_idx]
   ```

2. **Grid Search or Random Search**

   ```python
   from sklearn.model_selection import GridSearchCV

   param_grid = {
       'n_estimators': [100, 200, 300],
       'max_depth': [5, 10, 15],
       'min_samples_split': [2, 5, 10],
       'learning_rate': [0.01, 0.05, 0.1]
   }

   grid_search = GridSearchCV(
       XGBRegressor(),
       param_grid,
       cv=tscv,
       scoring='neg_mean_squared_error',
       n_jobs=-1
   )
   grid_search.fit(X_train, y_train)
   best_model = grid_search.best_estimator_
   ```

   **Deep Learning tuning options (for LSTM/GRU):**
   - Number of LSTM/GRU layers
   - Hidden units per layer (e.g., 32/64/128)
   - Dropout rate (e.g., 0.1 to 0.5)
   - Sequence length (timesteps)
   - Learning rate and batch size
   - EarlyStopping patience

3. **Performance Comparison**

   ```python
   # Baseline predictions
   baseline_pred = baseline_model.predict(X_test)
   baseline_rmse = np.sqrt(mean_squared_error(y_test, baseline_pred))

   # Tuned predictions
   tuned_pred = best_model.predict(X_test)
   tuned_rmse = np.sqrt(mean_squared_error(y_test, tuned_pred))

   # Improvement
   improvement = ((baseline_rmse - tuned_rmse) / baseline_rmse) * 100
   ```

4. **Visualizations**

   ```python
   # Actual vs Predicted
   plt.scatter(y_test, tuned_pred, alpha=0.5)
   plt.plot([y_test.min(), y_test.max()], [y_test.min(), y_test.max()], 'r--')

   # Residuals
   residuals = y_test - tuned_pred
   plt.hist(residuals, bins=30)

   # Metric comparison
   metrics_df.plot(kind='bar')
   ```

5. **Reflection** (Critical for marks)
   - What hyperparameters helped most?
   - Did improvement meet expectations?
   - What challenges did you face?
   - What would you do differently?
   - Key learnings from the full pipeline?

**Deliverables:**

1. Tuning strategy description
2. Hyperparameter search space
3. TimeSeriesSplit implementation
4. Before/after metrics table
5. Actual vs predicted plot
6. Residual plot
7. Reflection (500+ words)

**Evaluation Criteria:**

- Tuning strategy appropriateness (4 marks)
- Performance improvement (quantified) (4 marks)
- Visualization quality (4 marks)
- Depth of reflection (3 marks)

---

### **Phase 6: Mobile Application (30 Marks)**

**Objective:** Deploy trained model in working mobile app with real user interaction.

**Architecture:**

```
Flutter Mobile App
        ↓
    HTTP calls
        ↓
FastAPI Backend
        ↓
Load trained model from disk
        ↓
Preprocess input → Predict → Return JSON
```

**Deep Learning deployment options:**

- Serve LSTM/GRU from FastAPI using TensorFlow/Keras model files
- Optional on-device inference using TensorFlow Lite (advanced)

**Minimum Screens & Features:**

1. **Input Screen**
   - Date range picker (start_date, end_date)
   - Product category dropdown
   - Region / Store selection
   - Optional: Promo flag toggle
   - "Predict" button

2. **Results Screen**
   - Display predicted sales value(s)
   - Line chart showing forecast
   - Confidence interval (if available)
   - Loading spinner while API calls
   - Error message if API fails

3. **Historical Comparison Screen**
   - Compare predicted vs actual historical sales
   - Date range filter
   - Combined line chart (predicted + actual)
   - Metrics: prediction accuracy, MAPE

**Technical Deliverables:**

1. **FastAPI Backend**

   ```python
   from fastapi import FastAPI
   from pydantic import BaseModel
   import joblib

   app = FastAPI()
   model = joblib.load('models/tuned_model.pkl')
   preprocessor = joblib.load('models/preprocessor.pkl')

   class PredictionRequest(BaseModel):
       start_date: str
       end_date: str
       product_category: str
       region: str
       promo_flag: bool = False

   @app.post("/predict")
   def predict(request: PredictionRequest):
       # Preprocess input
       # Call model
       # Return JSON
       return {"prediction": value, "confidence": ci}

   @app.get("/health")
   def health():
       return {"status": "ok"}
   ```

2. **Flutter Screens**

   ```dart
   // Screen 1: Input
   class PredictionInputScreen extends StatefulWidget { ... }

   // Screen 2: Results
   class PredictionResultsScreen extends StatelessWidget { ... }

   // Screen 3: History
   class HistoricalComparisonScreen extends StatelessWidget { ... }

   // Service: API communication
   class SalesAPIService {
       Future<PredictionResponse> predict(request) { ... }
       Future<List<HistoricalData>> getHistory(filters) { ... }
   }
   ```

3. **UI/UX Requirements**
   - Clean, intuitive navigation
   - Responsive layout (works on different screen sizes)
   - Accessible colors (good contrast)
   - Loading states for API calls
   - Error handling with user-friendly messages
   - Professional design (Material Design 3)

4. **Documentation**
   - README with:
     - Setup instructions
     - How to run FastAPI backend
     - How to build and run Flutter app
     - API endpoint documentation
     - Troubleshooting guide

5. **Deliverables**
   - Flutter source code (GitHub link or ZIP)
   - APK file (Android)
   - Live demo or recorded video (max 5 mins)
   - Technical documentation

**Evaluation Criteria:**

- Model integration success (8 marks)
- Core functionality (input, forecast, results) (8 marks)
- UI/UX design quality (6 marks)
- Technical documentation (4 marks)
- Live demo quality (4 marks)

---

## 📅 Recommended Timeline

| Week         | Dates     | Tasks                                             |
| ------------ | --------- | ------------------------------------------------- |
| **Week 1**   | Apr 15-18 | Phase 1: Proposal + Lecturer approval             |
| **Week 2**   | Apr 19-21 | Phase 2: EDA + Insights report                    |
| **Week 3**   | Apr 22-23 | Phase 3: Preprocessing pipeline                   |
| **Week 3**   | Apr 23-24 | Phase 4: Model selection + Baseline comparison    |
| **Week 4**   | Apr 24-25 | Phase 5: Tuning + Evaluation visuals + Reflection |
| **Week 4**   | Apr 25-26 | Phase 6: FastAPI + Flutter integration            |
| **Deadline** | Apr 27    | Final report, notebook, APK, presentation         |

---

## 📦 Final Submission Checklist

- [ ] **PROPOSAL.pdf** (3 pages max, get lecturer approval)
- [ ] **FINAL_REPORT.pdf** (Phases 2-5, well-structured, 20-30 pages)
- [ ] **sales_forecasting_pipeline.ipynb** (fully executed, all code + outputs)
- [ ] **PRESENTATION_SLIDES.pptx** (10-minute presentation)
- [ ] **Mobile App Source Code** (GitHub link or ZIP with README)
- [ ] **APK file** or live demo video (max 5 mins)
- [ ] **requirements.txt** (Python dependencies)
- [ ] **API setup guide** (how to run FastAPI backend)
- [ ] **Contribution statement** (if group project: who did what)

---

## 🎓 Scoring Strategy to Maximize Marks

**Phase 1 (10 marks):** ✅ High-quality proposal = quick approval = start strong
**Phase 2 (15 marks):** ✅ Deep EDA = inform all later decisions = strong insights
**Phase 3 (15 marks):** ✅ Creative features = better model performance = more tuning gains
**Phase 4 (15 marks):** ✅ Include both classical ML and deep learning (LSTM/GRU) with clear comparison
**Phase 5 (15 marks):** ✅ Strong tuning + visualization + reflection = demonstrate understanding
**Phase 6 (30 marks):** ✅ Polished app + working demo + clear documentation = scores highest

**Total: 100 marks**

---

## ⚠️ Common Pitfalls to Avoid

1. ❌ **Data leakage in time splits** → Use TimeSeriesSplit only
2. ❌ **Unapproved proposal** → Get Phase 1 signed off before proceeding
3. ❌ **Weak feature engineering** → Invest time in lag/rolling/temporal features
4. ❌ **No visualization** → Include actual vs predicted, residuals, comparison charts
5. ❌ **App not working** → Test API integration thoroughly before demo
6. ❌ **No reflection** → Write thoughtful Phase 5 reflection (critical for marks)
7. ❌ **Missing documentation** → Explain every decision in report and code comments
8. ❌ **No deep learning model** → Include and justify LSTM/GRU to meet project expectation

---

## ✅ Next Steps

1. **Review this plan** and decide:
   - Which Kaggle dataset to use?
   - Group size and role distribution?
   - Preferred algorithm path (Classical: Linear/RandomForest/XGBoost + Deep Learning: LSTM/GRU)?

2. **I can help generate:**
   - Proposal template (ready to submit to lecturer)
   - Jupyter Notebook skeleton (Phases 2-5)
   - FastAPI template (backend API)
   - Flutter app template (mobile UI)
   - Final report outline (structured to rubric)

3. **Confirm** and I'll create starter files for your chosen dataset/approach.

---

**Ready to proceed?** Let me know:

- [ ] Which Kaggle sales dataset?
- [ ] Solo or group? (if group: how many members + roles)
- [ ] Start with proposal, notebook, or app?

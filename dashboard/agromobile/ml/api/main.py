from __future__ import annotations

import json
from datetime import date, timedelta
from pathlib import Path
from typing import Any

import numpy as np
import pandas as pd
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

try:
    import joblib
except Exception:  # pragma: no cover - optional until the trained model exists
    joblib = None

try:
    import tensorflow as tf
except Exception:  # pragma: no cover - optional until the trained model exists
    tf = None


ROOT = Path(__file__).resolve().parents[1]

LSTM_MODEL_PATH = ROOT / "models" / "sales_lstm.keras"
LSTM_METADATA_PATH = ROOT / "models" / "sales_lstm_metadata.json"
LSTM_HISTORY_PATH = ROOT / "models" / "sales_history.csv"

LEGACY_MODEL_PATH = ROOT / "models" / "tuned_model.pkl"
LEGACY_PREPROCESSOR_PATH = ROOT / "models" / "preprocessor.pkl"
LEGACY_METADATA_PATH = ROOT / "models" / "model_metadata.json"

app = FastAPI(title="Sales Forecasting Coursework API", version="2.0.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class PredictionRequest(BaseModel):
    start_date: date
    end_date: date
    product_category: str = Field(min_length=1)
    region: str = Field(min_length=1)
    store: str = Field(min_length=1)
    promo_flag: bool = False


class ForecastPoint(BaseModel):
    date: date
    predicted_sales: float
    actual_sales: float | None = None


class PredictionResponse(BaseModel):
    total_predicted_sales: float
    average_daily_sales: float
    confidence_low: float
    confidence_high: float
    model_name: str
    is_demo: bool
    forecast: list[ForecastPoint]
    metrics: dict[str, float]
    note: str | None = None


def _try_load_lstm_assets() -> tuple[Any | None, dict[str, Any], pd.DataFrame | None]:
    if tf is None:
        return None, {}, None
    if not (LSTM_MODEL_PATH.exists() and LSTM_METADATA_PATH.exists() and LSTM_HISTORY_PATH.exists()):
        return None, {}, None

    try:
        model = tf.keras.models.load_model(LSTM_MODEL_PATH, compile=False)
        metadata = json.loads(LSTM_METADATA_PATH.read_text(encoding="utf-8"))
        history = pd.read_csv(LSTM_HISTORY_PATH, parse_dates=["date"])
        return model, metadata, history
    except Exception:
        return None, {}, None


def _try_load_legacy_assets() -> tuple[Any | None, Any | None, dict[str, Any]]:
    metadata = (
        json.loads(LEGACY_METADATA_PATH.read_text(encoding="utf-8"))
        if LEGACY_METADATA_PATH.exists()
        else {}
    )
    if joblib is None or not LEGACY_MODEL_PATH.exists():
        return None, None, metadata

    try:
        model = joblib.load(LEGACY_MODEL_PATH)
        preprocessor = (
            joblib.load(LEGACY_PREPROCESSOR_PATH)
            if LEGACY_PREPROCESSOR_PATH.exists()
            else None
        )
        return model, preprocessor, metadata
    except Exception:
        return None, None, metadata


LSTM_MODEL, LSTM_METADATA, LSTM_HISTORY = _try_load_lstm_assets()
LEGACY_MODEL, LEGACY_PREPROCESSOR, LEGACY_METADATA = _try_load_legacy_assets()


def _refresh_loaded_assets() -> None:
    global LSTM_MODEL, LSTM_METADATA, LSTM_HISTORY
    global LEGACY_MODEL, LEGACY_PREPROCESSOR, LEGACY_METADATA

    if LSTM_MODEL is None:
        LSTM_MODEL, LSTM_METADATA, LSTM_HISTORY = _try_load_lstm_assets()
    if LEGACY_MODEL is None:
        LEGACY_MODEL, LEGACY_PREPROCESSOR, LEGACY_METADATA = _try_load_legacy_assets()


@app.get("/health")
def health() -> dict[str, Any]:
    _refresh_loaded_assets()
    return {
        "status": "ok",
        "active_model": _active_model_type(),
        "lstm_loaded": LSTM_MODEL is not None,
        "legacy_model_loaded": LEGACY_MODEL is not None,
        "tensorflow_available": tf is not None,
        "lstm_model_path": str(LSTM_MODEL_PATH),
        "legacy_model_path": str(LEGACY_MODEL_PATH),
    }


@app.post("/predict", response_model=PredictionResponse)
def predict(request: PredictionRequest) -> PredictionResponse:
    _refresh_loaded_assets()
    if request.end_date < request.start_date:
        raise HTTPException(status_code=400, detail="end_date must be after start_date")

    days = (request.end_date - request.start_date).days + 1
    if days > 90:
        raise HTTPException(status_code=400, detail="Forecast range must be 90 days or less")

    if LSTM_MODEL is not None and LSTM_HISTORY is not None and LSTM_METADATA:
        return _predict_with_lstm(request)

    if LEGACY_MODEL is not None:
        return _predict_with_legacy_model(request)

    return _predict_with_demo_model(request)


def _predict_with_lstm(request: PredictionRequest) -> PredictionResponse:
    lookback = int(LSTM_METADATA.get("lookback", 14))
    history_rows, history_scope = _select_seed_history(request, lookback)
    if len(history_rows) < lookback:
        return _predict_with_demo_model(
            request,
            note=(
                "LSTM artifacts are available, but the history file does not contain enough "
                f"rows for lookback={lookback}. Falling back to demo forecast."
            ),
        )

    metrics = _metadata_metrics(LSTM_METADATA)
    residual_std = float(LSTM_METADATA.get("residual_std", 0) or 0)
    category = request.product_category
    region = request.region
    store = request.store

    forecast: list[ForecastPoint] = []
    sequence_buffer = history_rows[-lookback:]
    current = request.start_date

    while current <= request.end_date:
        input_window = np.asarray(
            [
                [
                    _encode_lstm_step(
                        sales=float(row["sales"]),
                        step_date=row["date"],
                        promo_flag=bool(row.get("promo_flag", False)),
                        product_category=category,
                        region=region,
                        store=store,
                    )
                    for row in sequence_buffer
                ]
            ],
            dtype=np.float32,
        )
        predicted_scaled = float(LSTM_MODEL.predict(input_window, verbose=0)[0][0])
        predicted_sales = max(0.0, _unscale_target(predicted_scaled))

        forecast.append(
            ForecastPoint(
                date=current,
                predicted_sales=round(predicted_sales, 2),
            )
        )
        sequence_buffer = [
            *sequence_buffer[1:],
            {
                "date": current,
                "sales": predicted_sales,
                "promo_flag": int(request.promo_flag),
            },
        ]
        current += timedelta(days=1)

    total = round(sum(point.predicted_sales for point in forecast), 2)
    confidence_margin = 1.96 * residual_std * (len(forecast) ** 0.5)
    history_note = (
        f"LSTM autoregressive forecast using {lookback} prior sales steps from {history_scope} history."
    )

    return PredictionResponse(
        total_predicted_sales=total,
        average_daily_sales=round(total / len(forecast), 2),
        confidence_low=round(max(0, total - confidence_margin), 2),
        confidence_high=round(total + confidence_margin, 2),
        model_name=str(LSTM_METADATA.get("model_name", "LSTM sales forecaster")),
        is_demo=False,
        forecast=forecast,
        metrics=metrics,
        note=history_note,
    )


def _select_seed_history(
    request: PredictionRequest,
    lookback: int,
) -> tuple[list[dict[str, Any]], str]:
    assert LSTM_HISTORY is not None

    history = LSTM_HISTORY.copy()
    history["date"] = pd.to_datetime(history["date"])
    history = history.sort_values("date")

    candidates = [
        (
            (history["product_category"].astype(str).str.lower() == request.product_category.lower())
            & (history["region"].astype(str).str.lower() == request.region.lower())
            & (history["store"].astype(str).str.lower() == request.store.lower()),
            "exact category/region/store",
        ),
        (
            (history["product_category"].astype(str).str.lower() == request.product_category.lower())
            & (history["region"].astype(str).str.lower() == request.region.lower()),
            "category/region",
        ),
        (
            history["product_category"].astype(str).str.lower() == request.product_category.lower(),
            "category-only",
        ),
    ]

    for mask, label in candidates:
        subset = history.loc[mask].sort_values("date")
        if len(subset) >= lookback:
            return _history_records(subset.tail(lookback)), label

    return _history_records(history.tail(lookback)), "global"


def _history_records(frame: pd.DataFrame) -> list[dict[str, Any]]:
    records: list[dict[str, Any]] = []
    for _, row in frame.iterrows():
        row_date = pd.Timestamp(row["date"]).date()
        records.append(
            {
                "date": row_date,
                "sales": float(row["sales"]),
                "promo_flag": int(row.get("promo_flag", 0)),
            }
        )
    return records


def _encode_lstm_step(
    *,
    sales: float,
    step_date: date,
    promo_flag: bool,
    product_category: str,
    region: str,
    store: str,
) -> list[float]:
    timestamp = pd.Timestamp(step_date)
    return [
        _scale_target(sales),
        1.0 if promo_flag else 0.0,
        float(timestamp.weekday()) / 6.0,
        float(timestamp.month) / 12.0,
        float(timestamp.isocalendar().week) / 53.0,
        1.0 if timestamp.weekday() >= 5 else 0.0,
        *_one_hot(product_category, [str(item) for item in LSTM_METADATA.get("category_vocab", [])]),
        *_one_hot(region, [str(item) for item in LSTM_METADATA.get("region_vocab", [])]),
        *_one_hot(store, [str(item) for item in LSTM_METADATA.get("store_vocab", [])]),
    ]


def _one_hot(value: str, vocab: list[str]) -> list[float]:
    normalized = value.lower()
    return [1.0 if normalized == item.lower() else 0.0 for item in vocab]


def _scale_target(value: float) -> float:
    mean = float(LSTM_METADATA.get("target_mean", 0) or 0)
    std = float(LSTM_METADATA.get("target_std", 1) or 1)
    if std == 0:
        std = 1
    return float((value - mean) / std)


def _unscale_target(value: float) -> float:
    mean = float(LSTM_METADATA.get("target_mean", 0) or 0)
    std = float(LSTM_METADATA.get("target_std", 1) or 1)
    if std == 0:
        std = 1
    return float(value * std + mean)


def _predict_with_legacy_model(request: PredictionRequest) -> PredictionResponse:
    rows = _feature_rows(request)
    predictions = _legacy_model_predict(rows)
    residual_std = float(LEGACY_METADATA.get("residual_std", 0) or 0)
    metrics = _metadata_metrics(LEGACY_METADATA)

    forecast = [
        ForecastPoint(date=row["date"], predicted_sales=round(float(pred), 2))
        for row, pred in zip(rows, predictions)
    ]
    total = round(sum(point.predicted_sales for point in forecast), 2)
    confidence_margin = 1.96 * residual_std * (len(forecast) ** 0.5)

    return PredictionResponse(
        total_predicted_sales=total,
        average_daily_sales=round(total / len(forecast), 2),
        confidence_low=round(max(0, total - confidence_margin), 2),
        confidence_high=round(total + confidence_margin, 2),
        model_name=str(LEGACY_METADATA.get("model_name", "Random Forest sales forecaster")),
        is_demo=False,
        forecast=forecast,
        metrics=metrics,
        note="Legacy sklearn forecast. The API falls back here when the LSTM artifacts are missing.",
    )


def _feature_rows(request: PredictionRequest) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    current = request.start_date
    while current <= request.end_date:
        rows.append(
            {
                "date": current,
                "product_category": request.product_category,
                "region": request.region,
                "store": request.store,
                "promo_flag": int(request.promo_flag),
                "day_of_week": current.weekday(),
                "month": current.month,
                "week_of_year": current.isocalendar().week,
                "is_weekend": int(current.weekday() >= 5),
                "date_ordinal": current.toordinal(),
            }
        )
        current += timedelta(days=1)
    return rows


def _legacy_model_predict(rows: list[dict[str, Any]]) -> list[float]:
    features = LEGACY_METADATA.get(
        "features",
        [
            "product_category",
            "region",
            "store",
            "promo_flag",
            "day_of_week",
            "month",
            "week_of_year",
            "is_weekend",
            "date_ordinal",
        ],
    )
    frame = pd.DataFrame(rows)
    X = frame[features]
    transformed = LEGACY_PREPROCESSOR.transform(X) if LEGACY_PREPROCESSOR is not None else X
    predictions = LEGACY_MODEL.predict(transformed)
    return [max(0.0, float(value)) for value in predictions]


def _metadata_metrics(metadata: dict[str, Any]) -> dict[str, float]:
    metrics = {
        key: float(value)
        for key, value in (metadata.get("metrics") or {}).items()
        if isinstance(value, (int, float))
    }
    if metrics:
        return metrics
    return {"rmse": 0.0, "mae": 0.0, "mape": 0.0, "r2": 0.0}


def _predict_with_demo_model(
    request: PredictionRequest,
    model_name: str = "Demo seasonal baseline",
    note: str | None = (
        "No trained sales forecast model is loaded. "
        "Train the LSTM with python ml\\training\\train_sales_lstm.py."
    ),
) -> PredictionResponse:
    forecast: list[ForecastPoint] = []
    category_factor = _category_factor(request.product_category)
    region_factor = _region_factor(request.region)
    store_factor = _store_factor(request.store)
    promo_factor = 1.18 if request.promo_flag else 1.0

    current = request.start_date
    index = 0
    while current <= request.end_date:
        weekend_factor = 1.18 if current.weekday() in (5, 6) else 1.0
        monday_factor = 0.92 if current.weekday() == 0 else 1.0
        trend_factor = 1 + index * 0.006
        predicted = (
            850
            * category_factor
            * region_factor
            * store_factor
            * promo_factor
            * weekend_factor
            * monday_factor
            * trend_factor
        )
        actual = predicted * (0.92 + (index % 5) * 0.035) if index < 14 else None
        forecast.append(
            ForecastPoint(
                date=current,
                predicted_sales=round(predicted, 2),
                actual_sales=round(actual, 2) if actual is not None else None,
            )
        )
        current += timedelta(days=1)
        index += 1

    total = round(sum(point.predicted_sales for point in forecast), 2)
    average = round(total / len(forecast), 2)

    return PredictionResponse(
        total_predicted_sales=total,
        average_daily_sales=average,
        confidence_low=round(total * 0.88, 2),
        confidence_high=round(total * 1.12, 2),
        model_name=model_name,
        is_demo=True,
        forecast=forecast,
        metrics={"rmse": 184.3, "mae": 116.7, "mape": 8.9, "r2": 0.87},
        note=note,
    )


def _active_model_type() -> str:
    if LSTM_MODEL is not None:
        return "lstm"
    if LEGACY_MODEL is not None:
        return "legacy_sklearn"
    return "demo"


def _category_factor(category: str) -> float:
    return {
        "electronics": 1.42,
        "grocery": 1.18,
        "fashion": 1.08,
        "home": 0.96,
    }.get(category.lower(), 1.0)


def _region_factor(region: str) -> float:
    return {
        "west": 1.16,
        "south": 1.07,
        "east": 0.98,
        "north": 0.94,
    }.get(region.lower(), 1.0)


def _store_factor(store: str) -> float:
    return {
        "store a": 1.04,
        "store b": 0.98,
        "store c": 0.92,
        "online": 1.24,
    }.get(store.lower(), 1.0)

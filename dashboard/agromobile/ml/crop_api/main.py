from __future__ import annotations

import json
from pathlib import Path
from typing import Any

import numpy as np
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

try:
    import tensorflow as tf
except Exception:  # pragma: no cover - optional until the trained model exists
    tf = None


ROOT = Path(__file__).resolve().parents[1]
MODEL_PATH = ROOT / "models" / "crop_mlp.keras"
METADATA_PATH = ROOT / "models" / "crop_mlp_metadata.json"

app = FastAPI(title="Crop Prediction API", version="1.0.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class PredictionRequest(BaseModel):
    N: float = Field(ge=0, le=250)
    P: float = Field(ge=0, le=250)
    K: float = Field(ge=0, le=250)
    temperature: float = Field(ge=-10, le=60)
    humidity: float = Field(ge=0, le=100)
    rainfall: float = Field(ge=0, le=4000)
    ph: float = Field(ge=0, le=14)


class PredictionResponse(BaseModel):
    predictedCrop: str
    confidence: float
    probabilities: dict[str, float]


def _try_load_assets() -> tuple[Any | None, dict[str, Any]]:
    if tf is None:
        return None, {}
    if not (MODEL_PATH.exists() and METADATA_PATH.exists()):
        return None, {}

    try:
        model = tf.keras.models.load_model(MODEL_PATH, compile=False)
        metadata = json.loads(METADATA_PATH.read_text(encoding="utf-8"))
        return model, metadata
    except Exception:
        return None, {}


MODEL, METADATA = _try_load_assets()


def _refresh_loaded_assets() -> None:
    global MODEL, METADATA
    if MODEL is None:
        MODEL, METADATA = _try_load_assets()


@app.get("/health")
def health() -> dict[str, Any]:
    _refresh_loaded_assets()
    return {
        "status": "ok",
        "model_loaded": MODEL is not None,
        "tensorflow_available": tf is not None,
        "model_name": METADATA.get("model_name", "Crop recommendation MLP"),
        "model_path": str(MODEL_PATH),
    }


@app.post("/predict", response_model=PredictionResponse)
def predict(request: PredictionRequest) -> PredictionResponse:
    _refresh_loaded_assets()
    if MODEL is None or not METADATA:
        raise HTTPException(
            status_code=503,
            detail=(
                "Crop model not loaded. Train it with "
                "python ml\\training\\train_crop_mlp.py"
            ),
        )

    vector = np.asarray([_scaled_features(request)], dtype=np.float32)
    raw_probs = MODEL.predict(vector, verbose=0)[0]
    labels = [str(label) for label in METADATA.get("labels", [])]
    probabilities = {
        label: round(float(prob), 6)
        for label, prob in sorted(
            zip(labels, raw_probs.tolist()),
            key=lambda item: item[1],
            reverse=True,
        )
    }
    if not probabilities:
        raise HTTPException(status_code=500, detail="Model metadata labels are missing")

    predicted_crop = max(probabilities, key=probabilities.get)
    confidence = float(probabilities[predicted_crop])

    return PredictionResponse(
        predictedCrop=predicted_crop,
        confidence=round(confidence, 6),
        probabilities=probabilities,
    )


def _scaled_features(request: PredictionRequest) -> list[float]:
    features = [str(name) for name in METADATA.get("features", [])]
    if not features:
        raise HTTPException(status_code=500, detail="Model metadata features are missing")

    mean_map = {str(key): float(value) for key, value in (METADATA.get("feature_mean") or {}).items()}
    std_map = {str(key): float(value) for key, value in (METADATA.get("feature_std") or {}).items()}
    values = request.model_dump()

    scaled: list[float] = []
    for feature in features:
        value = float(values[feature])
        mean = float(mean_map.get(feature, 0.0))
        std = float(std_map.get(feature, 1.0)) or 1.0
        scaled.append((value - mean) / std)
    return scaled

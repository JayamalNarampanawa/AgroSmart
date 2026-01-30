from fastapi import FastAPI
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
import joblib
import pandas as pd

# Load trained artifacts
rf_model = joblib.load("agrosmart_rf_crop_model.pkl")
label_encoder = joblib.load("agrosmart_label_encoder.pkl")
feature_order = joblib.load("agrosmart_feature_order.pkl")

app = FastAPI(title="AgroSmart ML API")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173"],  # your Vite dev server
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class PredictRequest(BaseModel):
    N: float
    P: float
    K: float
    temperature: float
    humidity: float
    rainfall: float
    ph: float

@app.get("/")
def root():
    return {"status": "ok", "message": "AgroSmart ML API running"}

@app.post("/predict")
def predict(req: PredictRequest):
    row = {
        "N": req.N,
        "P": req.P,
        "K": req.K,
        "temperature": req.temperature,
        "humidity": req.humidity,
        "rainfall": req.rainfall,
        "ph": req.ph,
    }

    X = pd.DataFrame([row])[feature_order]

    pred_id = rf_model.predict(X)[0]
    pred_crop = label_encoder.inverse_transform([pred_id])[0]

    proba = rf_model.predict_proba(X)[0]
    probs = {
        label: float(p)
        for label, p in zip(label_encoder.classes_, proba)
    }

    return {
        "predictedCrop": pred_crop,
        "confidence": float(max(proba)),
        "probabilities": probs
    }

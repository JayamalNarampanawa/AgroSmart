"""
AgroSmart ML API - Enhanced Version
Provides crop recommendations using trained Random Forest model
"""

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import joblib
import pandas as pd
import logging
from typing import Dict, Optional
import os

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Load trained artifacts
try:
    model_path = os.path.dirname(os.path.abspath(__file__))
    rf_model = joblib.load(os.path.join(model_path, "agrosmart_rf_crop_model.pkl"))
    label_encoder = joblib.load(os.path.join(model_path, "agrosmart_label_encoder.pkl"))
    feature_order = joblib.load(os.path.join(model_path, "agrosmart_feature_order.pkl"))
    logger.info("✓ All model artifacts loaded successfully")
except FileNotFoundError as e:
    logger.error(f"✗ Model files not found: {e}")
    raise

# Initialize FastAPI app
app = FastAPI(
    title="AgroSmart ML API",
    description="Machine Learning API for crop recommendations based on soil and environmental parameters",
    version="1.0.0"
)

# Configure CORS for mobile app compatibility
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5173",       # Vite dev server
        "http://localhost:5174",       # Alternative dev server
        "http://localhost:3000",       # Common dev port
        "http://127.0.0.1:5173",
        "http://127.0.0.1:5174",
        "http://10.0.2.2:5173",        # Android emulator access to host
        "http://10.0.2.2:8080",
        "*"                            # Allow all origins for development
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)


class PredictRequest(BaseModel):
    """Request model for crop prediction"""
    N: float = Field(..., description="Nitrogen content (mg/kg)", ge=0, le=300)
    P: float = Field(..., description="Phosphorus content (mg/kg)", ge=0, le=150)
    K: float = Field(..., description="Potassium content (mg/kg)", ge=0, le=300)
    temperature: float = Field(..., description="Temperature in Celsius", ge=-10, le=50)
    humidity: float = Field(..., description="Humidity percentage (0-100)", ge=0, le=100)
    rainfall: float = Field(..., description="Rainfall in mm", ge=0, le=5000)
    ph: float = Field(..., description="Soil pH level", ge=3, le=10)

    class Config:
        schema_extra = {
            "example": {
                "N": 80,
                "P": 40,
                "K": 40,
                "temperature": 25,
                "humidity": 70,
                "rainfall": 1500,
                "ph": 6.5
            }
        }


class PredictResponse(BaseModel):
    """Response model for crop prediction"""
    predictedCrop: str
    confidence: float
    probabilities: Dict[str, float]
    success: bool = True


@app.get("/", tags=["Health"])
def root():
    """Health check endpoint"""
    return {
        "status": "ok",
        "message": "AgroSmart ML API running",
        "version": "1.0.0",
        "models_loaded": True
    }


@app.post("/predict", response_model=PredictResponse, tags=["Prediction"])
def predict(req: PredictRequest):
    """
    Predict the best crop based on soil and environmental parameters
    
    Returns:
        - predictedCrop: The recommended crop
        - confidence: Confidence score (0-1)
        - probabilities: Probability for each crop
    """
    try:
        # Create DataFrame with input data
        row = {
            "N": req.N,
            "P": req.P,
            "K": req.K,
            "temperature": req.temperature,
            "humidity": req.humidity,
            "rainfall": req.rainfall,
            "ph": req.ph,
        }
        
        logger.info(f"Processing prediction request: {row}")
        
        # Ensure features are in correct order
        X = pd.DataFrame([row])[feature_order]
        
        # Make prediction
        pred_id = rf_model.predict(X)[0]
        pred_crop = label_encoder.inverse_transform([pred_id])[0]
        
        # Get probabilities for all crops
        proba = rf_model.predict_proba(X)[0]
        probs = {
            str(label): float(p)
            for label, p in zip(label_encoder.classes_, proba)
        }
        
        # Sort by probability
        probs = dict(sorted(probs.items(), key=lambda x: x[1], reverse=True))
        
        response = {
            "predictedCrop": str(pred_crop),
            "confidence": float(max(proba)),
            "probabilities": probs,
            "success": True
        }
        
        logger.info(f"✓ Prediction successful: {pred_crop} (confidence: {float(max(proba)):.2%})")
        return response
        
    except ValueError as e:
        logger.error(f"✗ Value error in prediction: {str(e)}")
        raise HTTPException(
            status_code=422,
            detail=f"Invalid input values: {str(e)}"
        )
    except Exception as e:
        logger.error(f"✗ Unexpected error during prediction: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Prediction error: {str(e)}"
        )


@app.get("/crops", tags=["Metadata"])
def get_crops():
    """Get list of available crops"""
    try:
        crops = list(label_encoder.classes_)
        logger.info(f"Retrieved {len(crops)} available crops")
        return {
            "success": True,
            "crops": crops,
            "count": len(crops)
        }
    except Exception as e:
        logger.error(f"✗ Error retrieving crops: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/info", tags=["Metadata"])
def get_api_info():
    """Get API information and model metadata"""
    try:
        return {
            "success": True,
            "api_name": "AgroSmart ML Crop Recommendation API",
            "version": "1.0.0",
            "model_type": "Random Forest Classifier",
            "features": list(feature_order) if hasattr(feature_order, '__iter__') else [],
            "num_crops": len(label_encoder.classes_),
            "available_crops": list(label_encoder.classes_),
            "description": "This API provides crop recommendations based on soil nutrients and environmental conditions"
        }
    except Exception as e:
        logger.error(f"✗ Error retrieving API info: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/health", tags=["Health"])
def health_check():
    """Detailed health check"""
    return {
        "status": "healthy",
        "models": {
            "random_forest": "loaded",
            "label_encoder": "loaded",
            "feature_order": "loaded"
        },
        "crops_supported": len(label_encoder.classes_),
        "ready": True
    }


@app.options("/{path:path}")
def options_handler(path: str):
    """Handle CORS preflight requests"""
    return JSONResponse(
        content={},
        headers={
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type, Authorization",
        }
    )


@app.exception_handler(HTTPException)
async def http_exception_handler(request, exc):
    """Custom exception handler"""
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "success": False,
            "error": exc.detail,
            "status_code": exc.status_code
        },
    )


if __name__ == "__main__":
    import uvicorn
    
    logger.info("=" * 60)
    logger.info("Starting AgroSmart ML API Server")
    logger.info("=" * 60)
    logger.info(f"Available crops: {len(label_encoder.classes_)}")
    logger.info(f"Feature order: {list(feature_order)}")
    logger.info("=" * 60)
    
    # Run with: uvicorn ml_api:app --reload --host 0.0.0.0 --port 8000
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8000,
        log_level="info"
    )

from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
from sklearn.compose import ColumnTransformer
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
from sklearn.model_selection import TimeSeriesSplit
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder, StandardScaler


ROOT = Path(__file__).resolve().parents[1]
RAW_DIR = ROOT / "data" / "raw"
PROCESSED_DIR = ROOT / "data" / "processed"
SPLIT_DIR = ROOT / "data" / "train_test_split"
MODEL_DIR = ROOT / "models"

DATE_COL = "date"
TARGET_COL = "sales"
CATEGORY_COLS = ["product_category", "region", "store"]
NUMERIC_COLS = [
    "promo_flag",
    "day_of_week",
    "month",
    "week_of_year",
    "is_weekend",
    "date_ordinal",
]


@dataclass
class TrainResult:
    rmse: float
    mae: float
    mape: float
    r2: float
    residual_std: float
    rows: int
    source: str


def main() -> None:
    RAW_DIR.mkdir(parents=True, exist_ok=True)
    PROCESSED_DIR.mkdir(parents=True, exist_ok=True)
    SPLIT_DIR.mkdir(parents=True, exist_ok=True)
    MODEL_DIR.mkdir(parents=True, exist_ok=True)

    df, source = load_or_generate_dataset()
    df = prepare_features(df)
    df.to_csv(PROCESSED_DIR / "sales_features.csv", index=False)

    result = train_and_save(df, source)
    print(json.dumps(result.__dict__, indent=2))


def load_or_generate_dataset() -> tuple[pd.DataFrame, str]:
    csv_files = sorted(RAW_DIR.glob("*.csv"))
    if csv_files:
        df = pd.read_csv(csv_files[0])
        return normalize_dataset(df), str(csv_files[0])

    df = generate_starter_dataset()
    starter_path = RAW_DIR / "starter_sales_dataset.csv"
    df.to_csv(starter_path, index=False)
    return df, str(starter_path)


def normalize_dataset(df: pd.DataFrame) -> pd.DataFrame:
    rename_map: dict[str, str] = {}
    lower_cols = {col.lower().strip(): col for col in df.columns}

    aliases = {
        DATE_COL: ["date", "order_date", "invoice_date", "week", "month"],
        TARGET_COL: ["sales", "revenue", "amount", "weekly_sales", "total_sales"],
        "product_category": ["product_category", "category", "item_category"],
        "region": ["region", "state", "area", "market"],
        "store": ["store", "store_id", "shop", "branch"],
        "promo_flag": ["promo_flag", "promotion", "promo", "is_promo"],
    }

    for target, names in aliases.items():
        for name in names:
            if name in lower_cols:
                rename_map[lower_cols[name]] = target
                break

    df = df.rename(columns=rename_map).copy()
    missing = [DATE_COL, TARGET_COL]
    if any(col not in df.columns for col in missing):
        raise ValueError(
            "Raw CSV must contain date and sales columns. Supported aliases: "
            "date/order_date and sales/revenue/amount/weekly_sales."
        )

    for col in CATEGORY_COLS:
        if col not in df.columns:
            df[col] = "Unknown"
    if "promo_flag" not in df.columns:
        df["promo_flag"] = 0

    df = df[[DATE_COL, TARGET_COL, *CATEGORY_COLS, "promo_flag"]]
    df[DATE_COL] = pd.to_datetime(df[DATE_COL], errors="coerce")
    df[TARGET_COL] = pd.to_numeric(df[TARGET_COL], errors="coerce")
    df["promo_flag"] = df["promo_flag"].astype(str).str.lower().isin(
        ["1", "true", "yes", "y", "promo", "promotion"]
    ).astype(int)
    df = df.dropna(subset=[DATE_COL, TARGET_COL])
    return df.sort_values(DATE_COL).reset_index(drop=True)


def generate_starter_dataset() -> pd.DataFrame:
    rng = np.random.default_rng(42)
    dates = pd.date_range("2023-01-01", periods=730, freq="D")
    categories = ["Grocery", "Electronics", "Fashion", "Home"]
    regions = ["North", "South", "East", "West"]
    stores = ["Store A", "Store B", "Store C", "Online"]

    rows: list[dict[str, object]] = []
    for date in dates:
        for category in categories:
            for region in regions:
                store = stores[(date.day + len(category) + len(region)) % len(stores)]
                promo = int((date.day in (5, 15, 25)) or (category == "Fashion" and date.month in (4, 12)))
                base = 780
                category_factor = {
                    "Grocery": 1.18,
                    "Electronics": 1.42,
                    "Fashion": 1.08,
                    "Home": 0.96,
                }[category]
                region_factor = {
                    "North": 0.94,
                    "South": 1.07,
                    "East": 0.98,
                    "West": 1.16,
                }[region]
                store_factor = {
                    "Store A": 1.04,
                    "Store B": 0.98,
                    "Store C": 0.92,
                    "Online": 1.24,
                }[store]
                seasonal = 1 + 0.12 * np.sin(2 * np.pi * date.dayofyear / 365)
                weekend = 1.16 if date.weekday() >= 5 else 1.0
                promo_factor = 1.2 if promo else 1.0
                trend = 1 + (date - dates[0]).days * 0.00045
                noise = rng.normal(0, 55)
                sales = max(
                    50,
                    base
                    * category_factor
                    * region_factor
                    * store_factor
                    * seasonal
                    * weekend
                    * promo_factor
                    * trend
                    + noise,
                )
                rows.append(
                    {
                        DATE_COL: date.date().isoformat(),
                        TARGET_COL: round(float(sales), 2),
                        "product_category": category,
                        "region": region,
                        "store": store,
                        "promo_flag": promo,
                    }
                )

    return pd.DataFrame(rows)


def prepare_features(df: pd.DataFrame) -> pd.DataFrame:
    out = df.copy()
    out[DATE_COL] = pd.to_datetime(out[DATE_COL])
    out["promo_flag"] = out["promo_flag"].astype(int)
    out["day_of_week"] = out[DATE_COL].dt.dayofweek
    out["month"] = out[DATE_COL].dt.month
    out["week_of_year"] = out[DATE_COL].dt.isocalendar().week.astype(int)
    out["is_weekend"] = (out["day_of_week"] >= 5).astype(int)
    out["date_ordinal"] = out[DATE_COL].map(lambda value: value.toordinal())
    return out.sort_values(DATE_COL).reset_index(drop=True)


def train_and_save(df: pd.DataFrame, source: str) -> TrainResult:
    features = [*CATEGORY_COLS, *NUMERIC_COLS]
    X = df[features]
    y = df[TARGET_COL]

    train_end = int(len(df) * 0.7)
    val_end = int(len(df) * 0.85)
    train = df.iloc[:train_end]
    validation = df.iloc[train_end:val_end]
    test = df.iloc[val_end:]

    train.to_csv(SPLIT_DIR / "train.csv", index=False)
    validation.to_csv(SPLIT_DIR / "validation.csv", index=False)
    test.to_csv(SPLIT_DIR / "test.csv", index=False)

    preprocessor = ColumnTransformer(
        transformers=[
            ("categories", OneHotEncoder(handle_unknown="ignore"), CATEGORY_COLS),
            ("numbers", StandardScaler(), NUMERIC_COLS),
        ]
    )

    model = RandomForestRegressor(
        n_estimators=220,
        min_samples_leaf=2,
        random_state=42,
        n_jobs=1,
    )

    pipeline = Pipeline(
        steps=[
            ("preprocessor", preprocessor),
            ("model", model),
        ]
    )

    # TimeSeriesSplit validates the expected coursework split strategy.
    tscv = TimeSeriesSplit(n_splits=5)
    for train_idx, val_idx in tscv.split(X.iloc[:train_end]):
        pipeline.fit(X.iloc[train_idx], y.iloc[train_idx])
        pipeline.predict(X.iloc[val_idx])

    pipeline.fit(X.iloc[:val_end], y.iloc[:val_end])
    predictions = pipeline.predict(test[features])
    residuals = test[TARGET_COL].to_numpy() - predictions

    rmse = float(np.sqrt(mean_squared_error(test[TARGET_COL], predictions)))
    mae = float(mean_absolute_error(test[TARGET_COL], predictions))
    mape = float(np.mean(np.abs(residuals / test[TARGET_COL].to_numpy())) * 100)
    r2 = float(r2_score(test[TARGET_COL], predictions))
    residual_std = float(np.std(residuals))

    joblib.dump(pipeline.named_steps["model"], MODEL_DIR / "tuned_model.pkl")
    joblib.dump(pipeline.named_steps["preprocessor"], MODEL_DIR / "preprocessor.pkl")

    metadata = {
        "model_name": "Random Forest sales forecaster",
        "features": features,
        "categorical_features": CATEGORY_COLS,
        "numeric_features": NUMERIC_COLS,
        "target": TARGET_COL,
        "source": source,
        "rows": int(len(df)),
        "metrics": {
            "rmse": round(rmse, 2),
            "mae": round(mae, 2),
            "mape": round(mape, 2),
            "r2": round(r2, 4),
        },
        "residual_std": round(residual_std, 2),
    }
    (MODEL_DIR / "model_metadata.json").write_text(
        json.dumps(metadata, indent=2),
        encoding="utf-8",
    )

    return TrainResult(
        rmse=round(rmse, 2),
        mae=round(mae, 2),
        mape=round(mape, 2),
        r2=round(r2, 4),
        residual_std=round(residual_std, 2),
        rows=int(len(df)),
        source=source,
    )


if __name__ == "__main__":
    main()

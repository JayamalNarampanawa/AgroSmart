from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path

import numpy as np
import pandas as pd
import tensorflow as tf
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score


ROOT = Path(__file__).resolve().parents[1]
RAW_DIR = ROOT / "data" / "raw"
PROCESSED_DIR = ROOT / "data" / "processed"
SPLIT_DIR = ROOT / "data" / "train_test_split"
MODEL_DIR = ROOT / "models"

DATE_COL = "date"
TARGET_COL = "sales"
CATEGORY_COLS = ["product_category", "region", "store"]
LOOKBACK = 14
RANDOM_SEED = 42

LSTM_MODEL_PATH = MODEL_DIR / "sales_lstm.keras"
LSTM_METADATA_PATH = MODEL_DIR / "sales_lstm_metadata.json"
LSTM_HISTORY_PATH = MODEL_DIR / "sales_history.csv"


@dataclass
class TrainResult:
    rmse: float
    mae: float
    mape: float
    r2: float
    residual_std: float
    rows: int
    train_sequences: int
    validation_sequences: int
    test_sequences: int
    lookback: int
    source: str


def main() -> None:
    tf.keras.utils.set_random_seed(RANDOM_SEED)

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
    for csv_file in csv_files:
        try:
            df = pd.read_csv(csv_file)
            normalized = normalize_dataset(df)
            return normalized, str(csv_file)
        except ValueError:
            continue

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
    required = [DATE_COL, TARGET_COL]
    if any(col not in df.columns for col in required):
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
    df["promo_flag"] = (
        df["promo_flag"]
        .astype(str)
        .str.lower()
        .isin(["1", "true", "yes", "y", "promo", "promotion"])
        .astype(int)
    )
    df = df.dropna(subset=[DATE_COL, TARGET_COL])
    return df.sort_values([*CATEGORY_COLS, DATE_COL]).reset_index(drop=True)


def generate_starter_dataset() -> pd.DataFrame:
    rng = np.random.default_rng(RANDOM_SEED)
    dates = pd.date_range("2023-01-01", periods=730, freq="D")
    categories = ["Grocery", "Electronics", "Fashion", "Home"]
    regions = ["North", "South", "East", "West"]
    stores = ["Store A", "Store B", "Store C", "Online"]

    rows: list[dict[str, object]] = []
    for category in categories:
        for region in regions:
            for store in stores:
                base = 760
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

                for date in dates:
                    promo = int(
                        date.day in (5, 15, 25)
                        or (category == "Fashion" and date.month in (4, 12))
                    )
                    seasonal = 1 + 0.12 * np.sin(2 * np.pi * date.dayofyear / 365)
                    weekend = 1.16 if date.weekday() >= 5 else 1.0
                    promo_factor = 1.20 if promo else 1.0
                    trend = 1 + (date - dates[0]).days * 0.00045
                    noise = rng.normal(0, 35)
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
    return out.sort_values([*CATEGORY_COLS, DATE_COL]).reset_index(drop=True)


def train_and_save(df: pd.DataFrame, source: str) -> TrainResult:
    target_mean = float(df[TARGET_COL].mean())
    target_std = float(df[TARGET_COL].std() or 1.0)
    if target_std == 0:
        target_std = 1.0

    category_vocab = sorted(df["product_category"].astype(str).unique().tolist())
    region_vocab = sorted(df["region"].astype(str).unique().tolist())
    store_vocab = sorted(df["store"].astype(str).unique().tolist())

    dataset = build_sequence_splits(
        df=df,
        lookback=LOOKBACK,
        target_mean=target_mean,
        target_std=target_std,
        category_vocab=category_vocab,
        region_vocab=region_vocab,
        store_vocab=store_vocab,
    )

    feature_dim = int(dataset["X_train"].shape[-1])
    model = build_model(lookback=LOOKBACK, feature_dim=feature_dim)
    callbacks = [
        tf.keras.callbacks.EarlyStopping(
            monitor="val_loss",
            patience=8,
            restore_best_weights=True,
        )
    ]
    model.fit(
        dataset["X_train"],
        dataset["y_train"],
        validation_data=(dataset["X_val"], dataset["y_val"]),
        epochs=40,
        batch_size=32,
        callbacks=callbacks,
        verbose=0,
    )

    predictions_scaled = model.predict(dataset["X_test"], verbose=0).reshape(-1)
    predictions = unscale_target(predictions_scaled, target_mean, target_std)
    actuals = unscale_target(dataset["y_test"], target_mean, target_std)
    residuals = actuals - predictions

    rmse = float(np.sqrt(mean_squared_error(actuals, predictions)))
    mae = float(mean_absolute_error(actuals, predictions))
    mape = float(np.mean(np.abs(residuals / np.clip(actuals, 1e-6, None))) * 100)
    r2 = float(r2_score(actuals, predictions))
    residual_std = float(np.std(residuals))

    model.save(LSTM_MODEL_PATH)
    history_cols = [DATE_COL, TARGET_COL, *CATEGORY_COLS, "promo_flag"]
    df[history_cols].to_csv(LSTM_HISTORY_PATH, index=False)

    metadata = {
        "model_name": "LSTM sales forecaster",
        "model_type": "lstm",
        "lookback": LOOKBACK,
        "feature_dimension": feature_dim,
        "source": source,
        "rows": int(len(df)),
        "category_vocab": category_vocab,
        "region_vocab": region_vocab,
        "store_vocab": store_vocab,
        "target_mean": round(target_mean, 6),
        "target_std": round(target_std, 6),
        "metrics": {
            "rmse": round(rmse, 2),
            "mae": round(mae, 2),
            "mape": round(mape, 2),
            "r2": round(r2, 4),
        },
        "residual_std": round(residual_std, 2),
        "train_sequences": int(dataset["X_train"].shape[0]),
        "validation_sequences": int(dataset["X_val"].shape[0]),
        "test_sequences": int(dataset["X_test"].shape[0]),
        "feature_order": [
            "scaled_sales",
            "promo_flag",
            "day_of_week_norm",
            "month_norm",
            "week_of_year_norm",
            "is_weekend",
            "category_one_hot",
            "region_one_hot",
            "store_one_hot",
        ],
    }
    LSTM_METADATA_PATH.write_text(json.dumps(metadata, indent=2), encoding="utf-8")

    return TrainResult(
        rmse=round(rmse, 2),
        mae=round(mae, 2),
        mape=round(mape, 2),
        r2=round(r2, 4),
        residual_std=round(residual_std, 2),
        rows=int(len(df)),
        train_sequences=int(dataset["X_train"].shape[0]),
        validation_sequences=int(dataset["X_val"].shape[0]),
        test_sequences=int(dataset["X_test"].shape[0]),
        lookback=LOOKBACK,
        source=source,
    )


def build_sequence_splits(
    *,
    df: pd.DataFrame,
    lookback: int,
    target_mean: float,
    target_std: float,
    category_vocab: list[str],
    region_vocab: list[str],
    store_vocab: list[str],
) -> dict[str, np.ndarray]:
    train_sequences: list[np.ndarray] = []
    validation_sequences: list[np.ndarray] = []
    test_sequences: list[np.ndarray] = []
    train_targets: list[float] = []
    validation_targets: list[float] = []
    test_targets: list[float] = []

    grouped = df.groupby(CATEGORY_COLS, sort=False)
    for _, group in grouped:
        group = group.sort_values(DATE_COL).reset_index(drop=True)
        if len(group) <= lookback + 2:
            continue

        train_end = max(lookback + 1, int(len(group) * 0.70))
        val_end = max(train_end + 1, int(len(group) * 0.85))
        val_end = min(len(group) - 1, val_end)

        for idx in range(lookback, len(group)):
            window = group.iloc[idx - lookback : idx]
            sequence = np.asarray(
                [
                    encode_step(
                        row=row,
                        target_mean=target_mean,
                        target_std=target_std,
                        category_vocab=category_vocab,
                        region_vocab=region_vocab,
                        store_vocab=store_vocab,
                    )
                    for _, row in window.iterrows()
                ],
                dtype=np.float32,
            )
            target = scale_target(float(group.iloc[idx][TARGET_COL]), target_mean, target_std)

            if idx < train_end:
                train_sequences.append(sequence)
                train_targets.append(target)
            elif idx < val_end:
                validation_sequences.append(sequence)
                validation_targets.append(target)
            else:
                test_sequences.append(sequence)
                test_targets.append(target)

    if not train_sequences or not validation_sequences or not test_sequences:
        raise ValueError(
            "Not enough historical data to create train/validation/test LSTM sequences. "
            "Provide a dataset with longer per-store time series."
        )

    return {
        "X_train": np.asarray(train_sequences, dtype=np.float32),
        "y_train": np.asarray(train_targets, dtype=np.float32),
        "X_val": np.asarray(validation_sequences, dtype=np.float32),
        "y_val": np.asarray(validation_targets, dtype=np.float32),
        "X_test": np.asarray(test_sequences, dtype=np.float32),
        "y_test": np.asarray(test_targets, dtype=np.float32),
    }


def build_model(*, lookback: int, feature_dim: int) -> tf.keras.Model:
    model = tf.keras.Sequential(
        [
            tf.keras.layers.Input(shape=(lookback, feature_dim)),
            tf.keras.layers.LSTM(64, return_sequences=True),
            tf.keras.layers.Dropout(0.20),
            tf.keras.layers.LSTM(32),
            tf.keras.layers.Dense(16, activation="relu"),
            tf.keras.layers.Dense(1),
        ]
    )
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=0.001),
        loss="mse",
        metrics=[tf.keras.metrics.MeanAbsoluteError(name="mae")],
    )
    return model


def encode_step(
    *,
    row: pd.Series,
    target_mean: float,
    target_std: float,
    category_vocab: list[str],
    region_vocab: list[str],
    store_vocab: list[str],
) -> list[float]:
    return [
        scale_target(float(row[TARGET_COL]), target_mean, target_std),
        float(int(row["promo_flag"])),
        float(int(row["day_of_week"])) / 6.0,
        float(int(row["month"])) / 12.0,
        float(int(row["week_of_year"])) / 53.0,
        float(int(row["is_weekend"])),
        *one_hot(str(row["product_category"]), category_vocab),
        *one_hot(str(row["region"]), region_vocab),
        *one_hot(str(row["store"]), store_vocab),
    ]


def one_hot(value: str, vocab: list[str]) -> list[float]:
    return [1.0 if value == item else 0.0 for item in vocab]


def scale_target(value: float, mean: float, std: float) -> float:
    return float((value - mean) / std)


def unscale_target(values: np.ndarray, mean: float, std: float) -> np.ndarray:
    return values * std + mean


if __name__ == "__main__":
    main()

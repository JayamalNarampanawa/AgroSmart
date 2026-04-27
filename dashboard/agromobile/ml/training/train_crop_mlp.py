from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path

import numpy as np
import pandas as pd
import tensorflow as tf
from sklearn.metrics import accuracy_score, log_loss


ROOT = Path(__file__).resolve().parents[1]
RAW_DIR = ROOT / "data" / "raw"
MODEL_DIR = ROOT / "models"

RANDOM_SEED = 42
FEATURES = ["N", "P", "K", "temperature", "humidity", "rainfall", "ph"]
MODEL_PATH = MODEL_DIR / "crop_mlp.keras"
METADATA_PATH = MODEL_DIR / "crop_mlp_metadata.json"
DATASET_PATH = RAW_DIR / "starter_crop_dataset.csv"


CROP_SPECS: dict[str, dict[str, tuple[float, float]]] = {
    "Rice": {
        "N": (80, 120),
        "P": (20, 40),
        "K": (40, 80),
        "temperature": (20, 30),
        "humidity": (75, 90),
        "rainfall": (1500, 2250),
        "ph": (5.0, 7.0),
    },
    "Maize": {
        "N": (80, 120),
        "P": (30, 60),
        "K": (20, 60),
        "temperature": (21, 27),
        "humidity": (55, 75),
        "rainfall": (500, 1000),
        "ph": (5.5, 7.5),
    },
    "Wheat": {
        "N": (60, 100),
        "P": (20, 40),
        "K": (20, 40),
        "temperature": (12, 25),
        "humidity": (45, 65),
        "rainfall": (375, 650),
        "ph": (6.0, 7.5),
    },
    "Tomato": {
        "N": (80, 120),
        "P": (60, 80),
        "K": (60, 100),
        "temperature": (18, 28),
        "humidity": (60, 80),
        "rainfall": (500, 750),
        "ph": (6.0, 7.0),
    },
    "Cotton": {
        "N": (80, 120),
        "P": (40, 60),
        "K": (20, 40),
        "temperature": (21, 27),
        "humidity": (45, 65),
        "rainfall": (600, 1200),
        "ph": (6.0, 7.5),
    },
    "Sugarcane": {
        "N": (80, 120),
        "P": (30, 60),
        "K": (60, 100),
        "temperature": (21, 27),
        "humidity": (70, 88),
        "rainfall": (1200, 2250),
        "ph": (6.0, 7.5),
    },
    "Soybean": {
        "N": (20, 40),
        "P": (40, 60),
        "K": (40, 80),
        "temperature": (20, 30),
        "humidity": (55, 75),
        "rainfall": (450, 900),
        "ph": (6.0, 7.0),
    },
    "Potato": {
        "N": (80, 120),
        "P": (60, 80),
        "K": (80, 120),
        "temperature": (15, 25),
        "humidity": (55, 75),
        "rainfall": (500, 750),
        "ph": (5.0, 6.5),
    },
}


@dataclass
class TrainResult:
    accuracy: float
    log_loss_value: float
    rows: int
    class_count: int
    source: str


def main() -> None:
    tf.keras.utils.set_random_seed(RANDOM_SEED)
    RAW_DIR.mkdir(parents=True, exist_ok=True)
    MODEL_DIR.mkdir(parents=True, exist_ok=True)

    dataset = generate_dataset(samples_per_crop=280)
    dataset.to_csv(DATASET_PATH, index=False)

    result = train_and_save(dataset, source=str(DATASET_PATH))
    print(json.dumps(result.__dict__, indent=2))


def generate_dataset(samples_per_crop: int) -> pd.DataFrame:
    rng = np.random.default_rng(RANDOM_SEED)
    rows: list[dict[str, float | str]] = []

    for crop_name, spec in CROP_SPECS.items():
        for _ in range(samples_per_crop):
            sample: dict[str, float | str] = {"label": crop_name}
            for feature in FEATURES:
                low, high = spec[feature]
                center = (low + high) / 2
                spread = max((high - low) / 6, 0.15)
                value = float(rng.normal(center, spread))
                value = float(np.clip(value, low, high))
                sample[feature] = round(value, 3)

            # Add a small minority of edge cases near the crop bounds.
            if rng.random() < 0.18:
                for feature in FEATURES:
                    low, high = spec[feature]
                    sample[feature] = round(float(rng.choice([low, high])), 3)

            rows.append(sample)

    frame = pd.DataFrame(rows)
    return frame.sample(frac=1, random_state=RANDOM_SEED).reset_index(drop=True)


def train_and_save(dataset: pd.DataFrame, source: str) -> TrainResult:
    labels = sorted(dataset["label"].astype(str).unique().tolist())
    label_to_index = {label: idx for idx, label in enumerate(labels)}

    X = dataset[FEATURES].to_numpy(dtype=np.float32)
    y_idx = dataset["label"].map(label_to_index).to_numpy(dtype=np.int32)

    feature_mean = X.mean(axis=0)
    feature_std = X.std(axis=0)
    feature_std[feature_std == 0] = 1.0
    X_scaled = (X - feature_mean) / feature_std

    train_end = int(len(dataset) * 0.7)
    val_end = int(len(dataset) * 0.85)

    X_train = X_scaled[:train_end]
    y_train = y_idx[:train_end]
    X_val = X_scaled[train_end:val_end]
    y_val = y_idx[train_end:val_end]
    X_test = X_scaled[val_end:]
    y_test = y_idx[val_end:]

    y_train_cat = tf.keras.utils.to_categorical(y_train, num_classes=len(labels))
    y_val_cat = tf.keras.utils.to_categorical(y_val, num_classes=len(labels))

    model = build_model(input_dim=len(FEATURES), class_count=len(labels))
    callbacks = [
        tf.keras.callbacks.EarlyStopping(
            monitor="val_loss",
            patience=10,
            restore_best_weights=True,
        )
    ]
    model.fit(
        X_train,
        y_train_cat,
        validation_data=(X_val, y_val_cat),
        epochs=60,
        batch_size=32,
        verbose=0,
        callbacks=callbacks,
    )

    probabilities = model.predict(X_test, verbose=0)
    predicted_idx = probabilities.argmax(axis=1)

    accuracy = float(accuracy_score(y_test, predicted_idx))
    loss_value = float(log_loss(y_test, probabilities, labels=list(range(len(labels)))))

    model.save(MODEL_PATH)
    metadata = {
        "model_name": "Crop recommendation MLP",
        "model_type": "mlp_classifier",
        "features": FEATURES,
        "labels": labels,
        "label_to_index": label_to_index,
        "feature_mean": {name: float(value) for name, value in zip(FEATURES, feature_mean)},
        "feature_std": {name: float(value) for name, value in zip(FEATURES, feature_std)},
        "metrics": {
            "accuracy": round(accuracy, 4),
            "log_loss": round(loss_value, 4),
        },
        "rows": int(len(dataset)),
        "source": source,
    }
    METADATA_PATH.write_text(json.dumps(metadata, indent=2), encoding="utf-8")

    return TrainResult(
        accuracy=round(accuracy, 4),
        log_loss_value=round(loss_value, 4),
        rows=int(len(dataset)),
        class_count=len(labels),
        source=source,
    )


def build_model(*, input_dim: int, class_count: int) -> tf.keras.Model:
    model = tf.keras.Sequential(
        [
            tf.keras.layers.Input(shape=(input_dim,)),
            tf.keras.layers.Dense(64, activation="relu"),
            tf.keras.layers.Dropout(0.20),
            tf.keras.layers.Dense(32, activation="relu"),
            tf.keras.layers.Dense(class_count, activation="softmax"),
        ]
    )
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=0.001),
        loss="categorical_crossentropy",
        metrics=["accuracy"],
    )
    return model


if __name__ == "__main__":
    main()

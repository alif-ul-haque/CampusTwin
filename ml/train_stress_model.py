"""Train a Random Forest stress-level model on the features shared with the
CampusTwin habit database (sleep hours, physical activity, screen time).

Pipeline mirrors the notebook "Stress Level Prediction - Comparative Analysis":
RobustScaler -> SMOTE (train-time only) -> RandomForestClassifier, with a
compact tree size so the model can run fully on-device in the app.

Instead of exporting a giant unrolled m2cgen file, we serialize each decision
tree's arrays (children_left/right, feature, threshold, leaf values) into a
small JSON asset that the Flutter app traverses at runtime with a tiny tree
ensemble interpreter (lib/services/stress_model.dart).

App feature mapping at inference:
  feature[0] = sleep_hours          (hours)
  feature[1] = exercise_minutes/30  (physical activity on dataset scale)
  feature[2] = screen_time_hours    (hours)
Class index: 0 = low, 1 = moderate, 2 = high.
"""

import json
import os

import joblib
import numpy as np
import pandas as pd
from imblearn.over_sampling import SMOTE
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import (
    accuracy_score,
    balanced_accuracy_score,
    classification_report,
    confusion_matrix,
    f1_score,
)
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import RobustScaler

SEED = 42
FEATURES = ["sleep_duration", "physical_activity", "screen_time"]
LABELS = ["low", "moderate", "high"]

N_ESTIMATORS = 50
MAX_DEPTH = 6
MIN_SAMPLES_LEAF = 8

HERE = os.path.dirname(os.path.abspath(__file__))
DATA_PATH = os.path.join(HERE, "..", "ml_dataset", "extended_stress_detection_data.csv")


def prepare_data() -> pd.DataFrame:
    df = pd.read_csv(DATA_PATH)
    df.columns = df.columns.str.lower().str.strip()
    df["stress_detection"] = df["stress_detection"].replace("Medium", "Moderate")
    df["stress_detection"] = df["stress_detection"].map({"Low": 0, "Moderate": 1, "High": 2})
    df = df.drop_duplicates().reset_index(drop=True)
    df = df[FEATURES + ["stress_detection"]].dropna()
    return df


def main() -> None:
    df = prepare_data()
    X = df[FEATURES]
    y = df["stress_detection"]

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=SEED, stratify=y
    )

    scaler = RobustScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_test_scaled = scaler.transform(X_test)

    X_res, y_res = SMOTE(random_state=SEED).fit_resample(X_train_scaled, y_train)

    rf = RandomForestClassifier(
        random_state=SEED,
        n_estimators=N_ESTIMATORS,
        max_depth=MAX_DEPTH,
        min_samples_leaf=MIN_SAMPLES_LEAF,
        n_jobs=-1,
    )
    rf.fit(X_res, y_res)

    y_pred = rf.predict(X_test_scaled)
    y_proba = rf.predict_proba(X_test_scaled)

    print("=" * 60)
    print("FEATURES (common with CampusTwin habit DB):", FEATURES)
    print(f"Rows: {len(df)}  Train: {len(X_train)}  Test: {len(X_test)}")
    print(f"RF: {N_ESTIMATORS} trees, depth {MAX_DEPTH}, min_leaf {MIN_SAMPLES_LEAF}")
    print(f"Accuracy:          {accuracy_score(y_test, y_pred):.4f}")
    print(f"Balanced Accuracy: {balanced_accuracy_score(y_test, y_pred):.4f}")
    print(f"Macro F1:          {f1_score(y_test, y_pred, average='macro'):.4f}")
    print("=" * 60)
    print(classification_report(y_test, y_pred, target_names=LABELS, digits=3))
    print("Confusion Matrix [rows=true, cols=pred]:")
    print(confusion_matrix(y_test, y_pred))

    # ── Persist artifacts ──────────────────────────────────────────────
    model_path = os.path.join(HERE, "stress_rf.pkl")
    joblib.dump({"scaler": scaler, "model": rf}, model_path)
    print(f"Saved sklearn artifacts: {model_path}")

    asset = build_asset_json(scaler, rf)
    asset_path = os.path.join(HERE, "..", "assets", "stress_model.json")
    asset_path = os.path.normpath(asset_path)
    with open(asset_path, "w", encoding="utf-8") as f:
        json.dump(asset, f, separators=(",", ":"))
    print(f"Wrote model asset: {asset_path} ({os.path.getsize(asset_path) / 1e6:.2f} MB)")


def build_asset_json(scaler: RobustScaler, rf: RandomForestClassifier) -> dict:
    """Serializes the trained forest into a compact JSON structure that the
    Dart interpreter can walk directly."""
    trees = []
    for est in rf.estimators_:
        t = est.tree_
        trees.append(
            [
                t.children_left.tolist(),
                t.children_right.tolist(),
                t.feature.tolist(),
                t.threshold.tolist(),
                [round(v, 6) for v in t.value.reshape(-1, 3).flatten()],
            ]
        )
    return {
        "median": [round(float(m), 8) for m in scaler.center_],
        "iqr": [round(float(s), 8) for s in scaler.scale_],
        "classes": 3,
        "trees": trees,
    }


if __name__ == "__main__":
    main()
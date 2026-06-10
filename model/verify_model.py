#!/usr/bin/env python3
"""
Minimal sanity check for the converted Keras model.

Expects mobilenet_v2_1.0_224.h5 in the model/ directory.
"""

from pathlib import Path
import numpy as np

try:
    from tensorflow import keras
except Exception as exc:  # pragma: no cover - environment check
    raise SystemExit(f"TensorFlow is required: {exc}")


MODEL_PATH = Path(__file__).with_name("mobilenet_v2_1.0_224.h5")
if not MODEL_PATH.exists():
    raise SystemExit(f"Model file not found: {MODEL_PATH}")


def main() -> None:
    print(f"[verify] Loading {MODEL_PATH}")
    model = keras.models.load_model(MODEL_PATH)

    dummy = np.zeros((1, 224, 224, 3), dtype=np.float32)
    preds = model.predict(dummy, verbose=0)
    print(f"[verify] Output shape : {preds.shape}")
    print(f"[verify] Probabilities: {preds[0]}")
    print("[verify] OK")


if __name__ == "__main__":
    main()

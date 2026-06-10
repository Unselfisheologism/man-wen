#!/usr/bin/env bash
set -euo pipefail

MODEL_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$MODEL_DIR"

if [ ! -d nsfw_model ]; then
  echo "[*] Cloning GantMan/nsfw_model..."
  git clone https://github.com/GantMan/nsfw_model.git
else
  echo "[*] Using existing nsfw_model/ directory"
fi

KERAS_FILE="nsfw_model/mobilenet_v2_1.0_224.h5"
if [ ! -f "$KERAS_FILE" ]; then
  echo "[!] Expected Keras model not found at: $KERAS_FILE"
  echo "    Check the repo for the latest filename and update this script."
  exit 1
fi

cp "$KERAS_FILE" ./mobilenet_v2_1.0_224.h5
echo "[*] Keras model ready: mobilenet_v2_1.0_224.h5"

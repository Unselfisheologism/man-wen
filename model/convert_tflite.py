#!/usr/bin/env python3
"""
Converts GantMan/nsfw_model Keras model to TensorFlow Lite for Android.

Usage:
    python convert_tflite.py --input mobilenet_v2_1.0_224.h5 --output nsfw_detector.tflite
"""

import argparse
import os
import tensorflow as tf


def convert(input_path: str, output_path: str) -> None:
    if not os.path.exists(input_path):
        raise FileNotFoundError(f"Input model not found: {input_path}")

    print(f"[1/2] Loading Keras model from: {input_path}")
    model = tf.keras.models.load_model(input_path)
    print(f"      Inputs : {model.inputs}")
    print(f"      Outputs: {model.outputs}")

    print("[2/2] Converting to TFLite (FP16 quantized)")
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.target_spec.supported_types = [tf.float16]
    tflite_model = converter.convert()

    size_mb = len(tflite_model) / (1024 * 1024)
    with open(output_path, "wb") as f:
        f.write(tflite_model)

    print(f"      Saved : {output_path}")
    print(f"      Size  : {size_mb:.2f} MB")
    if size_mb > 10:
        print("[WARN] Model larger than 10MB. Consider INT8 quantization.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="NSFW TFLite converter")
    parser.add_argument("--input", required=True, help="Path to mobilenet_v2_1.0_224.h5")
    parser.add_argument("--output", default="nsfw_detector.tflite")
    args = parser.parse_args()
    convert(args.input, args.output)

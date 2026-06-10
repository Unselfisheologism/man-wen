#!/usr/bin/env python3
"""
Converts TFLite model (or original Keras) to Core ML for iOS.

Usage:
    # From Keras:
    python convert_coreml.py --input mobilenet_v2_1.0_224.h5 --output NSFWDetector.mlpackage

    # From TFLite:
    python convert_coreml.py --input nsfw_detector.tflite --output NSFWDetector.mlpackage --source tflite
"""

import argparse
import os

import coremltools as ct
import tensorflow as tf


def convert_keras(input_path: str, output_path: str) -> None:
    print(f"[CoreML] Loading Keras model: {input_path}")
    model = tf.keras.models.load_model(input_path)

    print("[CoreML] Converting to mlprogram (iOS 15+)")
    mlmodel = ct.convert(
        model,
        source="tensorflow",
        convert_to="mlprogram",
        minimum_deployment_target=ct.target.iOS15,
    )
    mlmodel.save(output_path)
    print(f"[CoreML] Saved: {output_path}")


def convert_tflite(input_path: str, output_path: str) -> None:
    print(f"[CoreML] Converting TFLite -> Core ML: {input_path}")
    size = os.path.getsize(input_path) / (1024 * 1024)
    print(f"[CoreML] Input size: {size:.2f} MB")
    print("[CoreML] Note: Core ML conversion from TFLite is limited; prefer Keras source if possible.")
    # Best-effort path; if this fails, use convert_keras() on the original .h5
    mlmodel = ct.convert(input_path, source="tensorflow")
    mlmodel.save(output_path)
    print(f"[CoreML] Saved: {output_path}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="NSFW Core ML converter")
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", default="NSFWDetector.mlpackage")
    parser.add_argument("--source", choices=["keras", "tflite"], default="keras")
    args = parser.parse_args()

    if args.source == "keras":
        convert_keras(args.input, args.output)
    else:
        convert_tflite(args.input, args.output)

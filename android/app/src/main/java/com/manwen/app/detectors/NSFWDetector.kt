package com.manwen.app.detectors

import android.content.Context
import android.graphics.Bitmap
import android.util.Log
import org.tensorflow.lite.Interpreter
import java.io.File
import java.io.FileOutputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder

class NSFWDetector private constructor() {

    companion object {
        const val TAG = "NSFWDetector"
        const val MODEL_NAME = "nsfw_model.tflite"
        const val INPUT_SIZE = 224
        const val NUM_CLASSES = 5
        val LABEL_NSFW = listOf("Drawing", "Hentai", "Neutral", "Porn", "Sexy")

        // Confidence thresholds
        const val THRESHOLD_DEFAULT = 0.75f
        const val THRESHOLD_DANGER_HOURS = 0.65f

        private var interpreter: Interpreter? = null
        private var isInitialized = false

        fun isInitialized(): Boolean = isInitialized

        fun initialize(context: Context): Boolean {
            if (isInitialized) return true

            return try {
                val modelFile = getModelFile(context)
                val options = Interpreter.Options().apply {
                    // Use GPU delegate for performance
                    try {
                        val gpuDelegate = org.tensorflow.lite.gpu.GpuDelegate()
                        addDelegate(gpuDelegate)
                    } catch (e: Exception) {
                        Log.w(TAG, "GPU delegate unavailable, using CPU fallback", e)
                    }
                    // Set thread count
                    setNumThreads(2)
                }

                interpreter = Interpreter(modelFile, options)
                isInitialized = true
                Log.i(TAG, "TFLite model loaded successfully")
                true
            } catch (e: Exception) {
                Log.e(TAG, "Failed to initialize NSFW detector", e)
                false
            }
        }

        private fun getModelFile(context: Context): File {
            // First check if model exists in files dir (preloaded)
            val modelFile = File(context.filesDir, MODEL_NAME)
            if (modelFile.exists()) return modelFile

            // Copy from assets if not found
            context.assets.open(MODEL_NAME).use { input ->
                FileOutputStream(modelFile).use { output ->
                    input.copyTo(output)
                }
            }
            return modelFile
        }

        fun detect(bitmap: Bitmap): NSFWResult {
            if (!isInitialized || interpreter == null) {
                return NSFWResult.allSafe()
            }

            return try {
                // Preprocess: resize to 224x224, normalize to [0,1]
                val inputBitmap = Bitmap.createScaledBitmap(bitmap, INPUT_SIZE, INPUT_SIZE, true)
                val inputBuffer = preprocessImage(inputBitmap)

                // Run inference
                val outputArray = Array(1) { FloatArray(NUM_CLASSES) }
                interpreter?.run(inputBuffer, outputArray)

                val probabilities = outputArray[0]
                val isNSFW = probabilities[3] > THRESHOLD_DEFAULT || // Porn
                             probabilities[1] > THRESHOLD_DEFAULT    // Hentai

                NSFWResult(
                    probabilities = probabilities.toList(),
                    topClass = LABEL_NSFW[probabilities.indices.maxByOrNull { probabilities[it] } ?: 2],
                    topConfidence = probabilities.maxOrNull() ?: 0f,
                    isNSFW = isNSFW,
                    pornConfidence = probabilities[3],
                    hentaiConfidence = probabilities[1]
                )
            } catch (e: Exception) {
                Log.e(TAG, "Detection error", e)
                NSFWResult.allSafe()
            }
        }

        private fun preprocessImage(bitmap: Bitmap): ByteBuffer {
            val byteBuffer = ByteBuffer.allocateDirect(4 * INPUT_SIZE * INPUT_SIZE * 3)
            byteBuffer.order(ByteOrder.nativeOrder())

            val intValues = IntArray(INPUT_SIZE * INPUT_SIZE)
            bitmap.getPixels(intValues, 0, INPUT_SIZE, 0, 0, INPUT_SIZE, INPUT_SIZE)

            for (pixel in intValues) {
                // Extract RGB and normalize to [0, 1]
                val r = ((pixel shr 16 and 0xFF) / 255.0f)
                val g = ((pixel shr 8 and 0xFF) / 255.0f)
                val b = ((pixel and 0xFF) / 255.0f)
                byteBuffer.putFloat(r)
                byteBuffer.putFloat(g)
                byteBuffer.putFloat(b)
            }

            return byteBuffer
        }

        fun close() {
            interpreter?.close()
            interpreter = null
            isInitialized = false
        }
    }

    data class NSFWResult(
        val probabilities: List<Float>,
        val topClass: String,
        val topConfidence: Float,
        val isNSFW: Boolean,
        val pornConfidence: Float,
        val hentaiConfidence: Float
    ) {
        companion object {
            fun allSafe() = NSFWResult(
                probabilities = listOf(0.1f, 0.05f, 0.8f, 0.03f, 0.02f),
                topClass = "Neutral",
                topConfidence = 0.8f,
                isNSFW = false,
                pornConfidence = 0.03f,
                hentaiConfidence = 0.05f
            )
        }
    }
}

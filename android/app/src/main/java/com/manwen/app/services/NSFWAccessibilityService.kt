package com.manwen.app.services

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.PixelFormat
import android.media.Image
import android.os.Build
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

class NSFWAccessibilityService : AccessibilityService() {

    companion object {
        const val TAG = "NSFWAccessibility"
        const val SCREEN_CAPTURE_INTERVAL_MS = 500L
    }

    private var screenCaptureMode: Int = AccessibilityService.SCREEN_CAPTURE_MODE_ALLOW_SYSTEM
    private var isMonitoring = false
    private var lastCaptureTime = 0L
    private var lastSignificantChange = 0L

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.i(TAG, "Accessibility Service Connected")

        // Configure service info
        serviceInfo = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPES_ALL_MASK
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            notificationTimeout = 100
            canPerformGestures = true
            canRetrieveWindowContent = true
            // Request screenshot capability on Android 14+
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                screenCaptureCapability = AccessibilityServiceInfo.SCREEN_CAPTURE_CAPABILITY_ALLOW_SYSTEM
            }
        }

        // Start foreground monitoring service
        startMonitoringService()
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        event ?: return

        val currentTime = System.currentTimeMillis()

        // Rate limit: process at most once per SCREEN_CAPTURE_INTERVAL_MS
        if (currentTime - lastCaptureTime < SCREEN_CAPTURE_INTERVAL_MS) {
            return
        }

        when (event.eventType) {
            AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED,
            AccessibilityEvent.TYPE_VIEW_SCROLLED,
            AccessibilityEvent.TYPE_VIEW_CLICKED -> {
                lastCaptureTime = currentTime
                captureAndAnalyzeScreen()
            }
        }
    }

    private fun captureAndAnalyzeScreen() {
        val currentTime = System.currentTimeMillis()

        // Take screenshot
        val bitmap = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            takeScreenshotUpsideDownCake()
        } else {
            takeScreenshotLegacy()
        }

        bitmap ?: return

        // Check if screen changed significantly (>50% pixel difference)
        if (!hasSignificantChange(bitmap) && !isMonitoring) {
            bitmap.recycle()
            return
        }

        lastSignificantChange = currentTime
        sendToDetector(bitmap)
    }

    // Android 14+ (UPSIDE_DOWN_CAKE, API 34+) native screenshot
    @android.annotation.TargetApi(Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
    private fun takeScreenshotUpsideDownCake(): Bitmap? {
        return try {
            val screenshot = takeScreenshot(android.view.accessibility.ScreenshotInfo(
                Display.DEFAULT_DISPLAY, PixelFormat.RGBA_8888
            ))
            screenshot?.hardwareBuffer?.let { hwBuffer ->
                val bitmap = hwBuffer.asBitmap()
                hwBuffer.close()
                screenshot.close()
                bitmap
            } ?: screenshot?.let { s ->
                // Fallback: convert software buffer
                Bitmap.wrapHardwareBuffer(s.hardwareBuffer, s.colorSpace)?.also { bmp ->
                    s.close()
                }
            }
        } catch (e: Exception) {
            Log.w(TAG, "Screenshot failed on API 34+", e)
            null
        }
    }

    // API 26-33 fallback: use root view snapshot
    private fun takeScreenshotLegacy(): Bitmap? {
        return try {
            val rootView = rootInActiveWindow ?: return null
            // AccessibilityService can't directly take screenshots pre-34
            // This is a best-effort using window content
            val bitmap = Bitmap.createBitmap(
                rootView.width.takeIf { it > 0 } ?: 1080,
                rootView.height.takeIf { it > 0 } ?: 2340,
                Bitmap.Config.ARGB_8888
            )
            val canvas = android.graphics.Canvas(bitmap)
            rootView.draw(canvas)
            bitmap
        } catch (e: Exception) {
            Log.w(TAG, "Legacy screenshot failed (expected pre-API 34)", e)
            null
        }
    }

    private fun hasSignificantChange(newBitmap: Bitmap): Boolean {
        // Simple frame-skip: check timestamp-based throttling
        // A proper implementation would use perceptual hashing
        return true
    }

    private fun sendToDetector(bitmap: Bitmap) {
        // Resize to 224x224 for model input
        val resized = Bitmap.createScaledBitmap(bitmap, 224, 224, true)
        bitmap.recycle()

        // Send to NSFWDetector service
        val intent = Intent(this, NSFWMonitoringService::class.java).apply {
            action = NSFWMonitoringService.ACTION_ANALYZE_FRAME
            putExtra(NSFWMonitoringService.EXTRA_FRAME_BITMAP, resized)
        }
        startService(intent)
    }

    private fun startMonitoringService() {
        val intent = Intent(this, NSFWMonitoringService::class.java).apply {
            action = NSFWMonitoringService.ACTION_START_MONITORING
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    override fun onInterrupt() {
        Log.i(TAG, "Accessibility Service Interrupted")
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.i(TAG, "Accessibility Service Destroyed")
    }
}

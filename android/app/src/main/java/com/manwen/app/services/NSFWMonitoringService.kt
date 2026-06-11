package com.manwen.app.services

import android.app.*
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat

class NSFWMonitoringService : Service() {

    companion object {
        const val TAG = "NSFWMonitoring"
        const val NOTIFICATION_CHANNEL_ID = "nsfw_monitoring_channel"
        const val NOTIFICATION_ID = 1001

        const val ACTION_START_MONITORING = "action.START_MONITORING"
        const val ACTION_ANALYZE_FRAME = "action.ANALYZE_FRAME"
        const val ACTION_STOP_MONITORING = "action.STOP_MONITORING"
        const val ACTION_BLOCK_DETECTED = "action.BLOCK_DETECTED"
        const val ACTION_CONTENT_SAFE = "action.CONTENT_SAFE"

        const val EXTRA_FRAME_BITMAP = "extra.FRAME_BITMAP"
        const val EXTRA_CONFIDENCE = "extra.CONFIDENCE"
        const val EXTRA_CLASS_NAME = "extra.CLASS_NAME"
        const val EXTRA_PACKAGE_NAME = "extra.PACKAGE_NAME"
    }

    private var wakeLock: PowerManager.WakeLock? = null
    private var isRunning = false
    private var consecutiveDetections = 0
    private val REQUIRED_CONSECUTIVE_DETECTIONS = 3
    private var lastBlockTime = 0L
    private val MIN_BLOCK_INTERVAL_MS = 5000L

    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                Intent.ACTION_SCREEN_OFF -> {
                    Log.i(TAG, "Screen off - pausing monitoring")
                    isRunning = false
                }
                Intent.ACTION_SCREEN_ON -> {
                    Log.i(TAG, "Screen on - resuming monitoring")
                    if (NSFWDetector.isInitialized()) {
                        isRunning = true
                    }
                }
            }
        }
    }

    override fun onBind(intent: Intent): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        Log.i(TAG, "Foreground Service Created")
        createNotificationChannel()
        registerScreenReceiver()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        intent?.let { handleIntent(it) }
        return START_STICKY
    }

    private fun handleIntent(intent: Intent) {
        when (intent.action) {
            ACTION_START_MONITORING -> startMonitoring()
            ACTION_ANALYZE_FRAME -> analyzeFrame(intent)
            ACTION_STOP_MONITORING -> stopMonitoring()
        }
    }

    private fun startMonitoring() {
        if (isRunning) return

        startForeground(NOTIFICATION_ID, createNotification())

        acquireWakeLock()
        isRunning = true
        NSFWDetector.initialize(applicationContext)

        // Register receiver to auto-pause when screen is off
        registerReceiver(screenReceiver, IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_SCREEN_OFF)
        })

        Log.i(TAG, "Monitoring started")
    }

    private fun stopMonitoring() {
        isRunning = false
        releaseWakeLock()
        try {
            unregisterReceiver(screenReceiver)
        } catch (e: Exception) {
            // Already unregistered
        }
        stopForeground(true)
        stopSelf()
        Log.i(TAG, "Monitoring stopped")
    }

    private fun analyzeFrame(intent: Intent) {
        if (!isRunning) return

        val bitmap = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(EXTRA_FRAME_BITMAP, Bitmap::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(EXTRA_FRAME_BITMAP)
        } ?: return

        val packageName = intent.getStringExtra(EXTRA_PACKAGE_NAME) ?: "unknown"
        val result = NSFWDetector.detect(bitmap)
        bitmap.recycle()

        val currentTime = System.currentTimeMillis()
        val isNSFW = result.isNSFW && result.confidence > 0.75f

        if (isNSFW) {
            consecutiveDetections++

            if (consecutiveDetections >= REQUIRED_CONSECUTIVE_DETECTIONS &&
                currentTime - lastBlockTime > MIN_BLOCK_INTERVAL_MS) {

                lastBlockTime = currentTime
                triggerBlockOverlay(result)

                // Broadcast for analytics/stats
                sendBroadcast(Intent(ACTION_BLOCK_DETECTED).apply {
                    putExtra(EXTRA_CONFIDENCE, result.confidence)
                    putExtra(EXTRA_CLASS_NAME, result.topClass)
                    putExtra(EXTRA_PACKAGE_NAME, packageName)
                })
                consecutiveDetections = 0
            }
        } else {
            consecutiveDetections = 0
            if (result.topClass == "Neutral" || result.topClass == "Drawing") {
                triggerSafeContent()
            }
        }
    }

    private fun triggerBlockOverlay(result: NSFWDetector.NSFWResult) {
        val overlayIntent = Intent(this, BlockingOverlayManager::class.java).apply {
            action = BlockingOverlayManager.ACTION_SHOW_BLOCK
            putExtra(BlockingOverlayManager.EXTRA_CONFIDENCE, result.confidence)
            putExtra(BlockingOverlayManager.EXTRA_CLASS_NAME, result.topClass)
        }
        startService(overlayIntent)
    }

    private fun triggerSafeContent() {
        // Auto-hide overlay if content becomes safe
        startService(Intent(this, BlockingOverlayManager::class.java).apply {
            action = BlockingOverlayManager.ACTION_HIDE_BLOCK
        })
    }

    private fun acquireWakeLock() {
        val powerManager = getSystemService(POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "ManWen:NSFWMonitoringWakeLock"
        ).apply {
            setReferenceCounted(false)
            acquire(10 * 60 * 1000L) // 10 minutes max
        }
    }

    private fun releaseWakeLock() {
        wakeLock?.let {
            if (it.isHeld) it.release()
        }
        wakeLock = null
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "NSFW Content Monitor",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Protecting your device from inappropriate content"
                setShowBadge(false)
                lockscreenVisibility = Notification.VISIBILITY_SECRET
            }
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        val pendingIntent = PendingIntent.getActivity(
            this, 0,
            packageManager.getLaunchIntentForPackage(packageName),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle("Man Wen is protecting you")
            .setContentText("Real-time content blocking is active")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setCategory(Notification.CATEGORY_SERVICE)
            .build()
    }

    override fun onDestroy() {
        super.onDestroy()
        releaseWakeLock()
    }
}

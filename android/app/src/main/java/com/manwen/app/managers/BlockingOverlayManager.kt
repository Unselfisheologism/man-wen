package com.manwen.app.managers

import android.app.ActivityManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BlurMaskFilter
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.ColorDrawable
import android.graphics.Paint
import android.graphics.drawable.Drawable
import android.os.Build
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.widget.ImageView
import androidx.core.content.getSystemService
import com.manwen.app.R

class BlockingOverlayManager(private val context: Context) {

    companion object {
        const val ACTION_SHOW_BLOCK = "action.SHOW_BLOCK"
        const val ACTION_HIDE_BLOCK = "action.HIDE_BLOCK"
        const val EXTRA_CONFIDENCE = "extra.CONFIDENCE"
        const val EXTRA_CLASS_NAME = "extra.CLASS_NAME"
        const val BLOCKER_TAG = "ManWenBlockingOverlay"

        const val AUTO_HIDE_DELAY_MS = 5000L
        const val FADE_ANIMATION_DURATION_MS = 300L

        fun handleIntent(service: Service, intent: Intent) {
            when (intent.action) {
                ACTION_SHOW_BLOCK -> BlockingOverlayManager(service).showBlock(intent)
                ACTION_HIDE_BLOCK -> BlockingOverlayManager(service).hideBlock()
            }
        }
    }

    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var isShowing = false

    private fun getWindowManager(): WindowManager {
        return windowManager ?: context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
            .also { windowManager = it }
    }

    fun showBlock(intent: Intent) {
        if (isShowing) {
            updateExistingBlock(intent)
            return
        }

        hideBlock() // Ensure clean slate

        val confidence = intent.getFloatExtra(EXTRA_CONFIDENCE, 0f)
        val className = intent.getStringExtra(EXTRA_CLASS_NAME) ?: "Blocked Content"

        val layoutParams = WindowManager.LayoutParams().apply {
            type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_SYSTEM_ALERT
            }
            flags = WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED
            format = PixelFormat.TRANSLUCENT
            width = WindowManager.LayoutParams.MATCH_PARENT
            height = WindowManager.LayoutParams.MATCH_PARENT
            gravity = Gravity.CENTER
        }

        val rootLayout = LayoutInflater.from(context).inflate(
            R.layout.overlay_blocking, null
        ) as ViewGroup

        setupOverlayContent(rootLayout, confidence, className)

        overlayView = rootLayout
        getWindowManager().addView(rootLayout, layoutParams)
        isShowing = true

        rootLayout.alpha = 0f
        rootLayout.animate()
            .alpha(1f)
            .setDuration(FADE_ANIMATION_DURATION_MS)
            .start()

        // Auto-hide after delay (content change handler will hide early if safe)
        rootLayout.postDelayed({
            hideBlock()
        }, AUTO_HIDE_DELAY_MS)
    }

    fun hideBlock() {
        overlayView?.let { view ->
            view.animate()
                .alpha(0f)
                .setDuration(FADE_ANIMATION_DURATION_MS)
                .withEndAction {
                    try {
                        getWindowManager().removeView(view)
                    } catch (e: Exception) {
                        // View already removed
                    }
                }
                .start()
        }
        overlayView = null
        isShowing = false
    }

    private fun updateExistingBlock(intent: Intent) {
        // Update overlay if already visible (rare — usually hide + re-show)
        val newClass = intent.getStringExtra(EXTRA_CLASS_NAME) ?: return
        overlayView?.findViewById<ImageView>(R.id.ivBlockIcon)?.let { icon ->
            // Brief pulse to indicate continued blocking
            icon.animate()
                .scaleX(1.2f)
                .scaleY(1.2f)
                .setDuration(150)
                .withEndAction {
                    icon.animate().scaleX(1f).scaleY(1f).duration = 150
                }
                .start()
        }
    }

    private fun setupOverlayContent(rootLayout: ViewGroup, confidence: Float, className: String) {
        val imageView = rootLayout.findViewById<ImageView>(R.id.ivBlockIcon)
        val textView = rootLayout.findViewById<android.widget.TextView>(R.id.tvBlockMessage)

        // Dark blur background
        val blurRadius = 20f
        val downsampleFactor = 8

        // Apply blur to background
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // Create a Drawable with blur effect
            rootLayout.background = createBlurredBackground(blurRadius)
        } else {
            rootLayout.setBackgroundColor(Color.parseColor("#CC000000"))
        }

        imageView.setImageResource(R.drawable.ic_block_shield)

        textView.text = when {
            confidence > 0.9f -> "⚠️ Inappropriate Content Blocked\n(${String.format("%.0f%%", confidence * 100)})"
            else -> "🛡️ Potentially Inappropriate Content\n(${String.format("%.0f%%", confidence * 100)})"
        }

        // Tap to dismiss
        rootLayout.setOnClickListener {
            hideBlock()
        }
    }

    fun cleanup() {
        hideBlock()
        windowManager = null
    }

    private fun createBlurredBackground(blurRadius: Float): Drawable {
        // Create a simple colored drawable for now
        // TODO: Implement proper blur effect using RenderScript or other API
        return ColorDrawable(Color.parseColor("#80000000"))
    }
}
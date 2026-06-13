package com.manwen.app

import android.content.Context
import android.os.Bundle
import android.util.Log
import android.widget.Toast
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.manwen.app.services.SiteBlockerService

class MainActivity: FlutterActivity() {
    private val channel = "com.manwen.app/manwen"

    override fun onCreate(savedInstanceState: Bundle?) {
        // Show a Toast if the previous launch crashed, pointing the user at
        // the saved crash log. consumePreviousCrashMarker deletes the marker
        // file so the Toast only shows ONCE per crash, not on every launch.
        runCatching {
            val previousCrash = CrashReporter.consumePreviousCrashMarker(this)
            if (previousCrash != null) {
                val desc = CrashReporter.describeLocations(this)
                Log.e("ManWenMain", "Previous crash at $previousCrash\n$desc")
                Toast.makeText(
                    this,
                    "Man Wen crashed at $previousCrash. Check Downloads for ManWen-crash-*.log",
                    Toast.LENGTH_LONG
                ).show()
            }
        }
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel).setMethodCallHandler { call, result ->
            when (call.method) {
                "startSiteBlocking" -> {
                    SiteBlockerService.start(this as Context)
                    result.success(true)
                }
                "stopSiteBlocking" -> {
                    SiteBlockerService.stop(this as Context)
                    result.success(true)
                }
                "openPaywall" -> {
                    // Keep legacy paywall
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}

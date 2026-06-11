package com.manwen.app

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.manwen.app.services.SiteBlockerService

class MainActivity: FlutterActivity() {
    private val channel = "com.manwen.app/manwen"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel).setMethodCallHandler { call, result ->
            when (call.method) {
                "startMonitoring" -> {
                    // Legacy NSFW method - now starts site blocking instead
                    SiteBlockerService.start(this as Context)
                    result.success(true)
                }
                "stopMonitoring" -> {
                    // Legacy NSFW method - now stops site blocking
                    SiteBlockerService.stop(this as Context)
                    result.success(true)
                }
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
package com.manwen.app

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.util.Log
import com.manwen.app.data.local.AppDatabase
import com.manwen.app.data.preferences.PreferencesManager
import java.io.File
import java.io.PrintWriter
import java.io.StringWriter

class ManWenApplication : Application() {
    lateinit var database: AppDatabase
    lateinit var preferences: PreferencesManager

    override fun onCreate() {
        super.onCreate()
        installCrashHandler()
        database = AppDatabase.getInstance(this)
        preferences = PreferencesManager(this)
        createNotificationChannels()
    }

    private fun installCrashHandler() {
        val previous = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler { thread, throwable ->
            try {
                val sw = StringWriter()
                throwable.printStackTrace(PrintWriter(sw))
                val crashText = buildString {
                    appendLine("=== Man Wen Crash ===")
                    appendLine("Time: ${System.currentTimeMillis()}")
                    appendLine("Thread: ${thread.name}")
                    appendLine("App version: ${packageManager.getPackageInfo(packageName, 0).versionName}")
                    appendLine("Android: ${Build.VERSION.RELEASE} (SDK ${Build.VERSION.SDK_INT})")
                    appendLine("Device: ${Build.MANUFACTURER} ${Build.MODEL}")
                    appendLine("ABI: ${Build.SUPPORTED_ABIS.joinToString()}")
                    appendLine()
                    appendLine(sw.toString())
                }
                // Write to external files dir (no permission needed, accessible to file managers)
                val outFile = File(getExternalFilesDir(null), "crash.log")
                outFile.writeText(crashText)
                Log.e("ManWenCrash", "Crash written to ${outFile.absolutePath}")
                Log.e("ManWenCrash", crashText)
            } catch (loggingFailure: Throwable) {
                Log.e("ManWenCrash", "Failed to persist crash log", loggingFailure)
            }
            previous?.uncaughtException(thread, throwable)
        }
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channels = listOf(
                NotificationChannel(
                    "site_blocker_channel",
                    "Site Blocker",
                    NotificationManager.IMPORTANCE_LOW
                ),
                NotificationChannel(
                    "urge_surfing_channel",
                    "Urge Surfing",
                    NotificationManager.IMPORTANCE_DEFAULT
                ),
                NotificationChannel(
                    "accountability_channel",
                    "Accountability Partner",
                    NotificationManager.IMPORTANCE_DEFAULT
                )
            )
            getSystemService(NotificationManager::class.java).createNotificationChannels(channels)
        }
    }
}
package com.manwen.app

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import com.manwen.app.data.local.AppDatabase
import com.manwen.app.data.preferences.PreferencesManager

class ManWenApplication : Application() {
    lateinit var database: AppDatabase
    lateinit var preferences: PreferencesManager

    override fun onCreate() {
        super.onCreate()
        database = AppDatabase.getInstance(this)
        preferences = PreferencesManager(this)
        createNotificationChannels()
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
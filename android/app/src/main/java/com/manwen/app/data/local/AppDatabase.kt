package com.manwen.app.data.local

import android.content.Context
import androidx.room.*
import com.manwen.app.data.local.entities.AppDatabaseEntities

@Database(
    entities = [
        UserProgress::class,
        DailyCheckIn::class,
        NSFWEvent::class,
        UrgeSurfingSession::class,
        ManagedApp::class,
        LocalAnalyticsEvent::class,
    ],
    version = 1,
    exportSchema = false
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun userProgressDao(): com.manwen.app.data.local.daos.UserProgressDao
    abstract fun dailyCheckInDao(): com.manwen.app.data.local.daos.DailyCheckInDao
    abstract fun nsfwEventDao(): com.manwen.app.data.local.daos.NSFWEventDao
    abstract fun urgeSurfingDao(): com.manwen.app.data.local.daos.UrgeSurfingDao
    abstract fun managedAppsDao(): com.manwen.app.data.local.daos.ManagedAppsDao
    abstract fun analyticsDao(): com.manwen.app.data.local.daos.AnalyticsDao

    companion object {
        @Volatile
        private var INSTANCE: AppDatabase? = null

        fun getInstance(context: Context): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "man_wen_db"
                )
                    .fallbackToDestructiveMigration()
                    .build()

                INSTANCE = instance
                instance
            }
        }
    }
}

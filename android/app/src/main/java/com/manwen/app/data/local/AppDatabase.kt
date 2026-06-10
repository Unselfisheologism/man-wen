package com.manwen.app.data.local

import android.content.Context
import androidx.room.*
import com.manwen.app.data.local.entities.AppDatabaseEntities
import net.sqlcipher.database.SQLiteDatabase
import net.sqlcipher.database.SupportFactory

@Database(
    entities = [
        AppDatabaseEntities.UserProgress::class,
        AppDatabaseEntities.DailyCheckIn::class,
        AppDatabaseEntities.NSFWEvent::class,
        AppDatabaseEntities.UrgeSurfingSession::class,
        AppDatabaseEntities.ManagedApp::class,
        AppDatabaseEntities.LocalAnalyticsEvent::class,
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
                val masterKey = androidx.room.room.RoomDatabase.Builder(context, AppDatabase::class.java, "man_wen_db")
                // For encrypted DB with SQLCipher, use:
                // val passphrase = SQLiteDatabase.getBytes("man_wen_encryption_key".toCharArray())
                // val factory = SupportFactory(passphrase)
                // val instance = Room.databaseBuilder(context, AppDatabase::class.java, "man_wen_db")
                //     .openHelperFactory(factory)
                //     .fallbackToDestructiveMigration()
                //     .build()

                // Unencrypted:
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

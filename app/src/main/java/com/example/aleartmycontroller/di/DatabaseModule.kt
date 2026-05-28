package com.example.aleartmycontroller.di

import android.content.Context
import com.example.aleartmycontroller.BuildConfig
import androidx.room.Room
import com.example.aleartmycontroller.data.local.AppDatabase
import com.example.aleartmycontroller.data.local.dao.AmcAttachmentQueueDao
import com.example.aleartmycontroller.data.local.dao.AmcDraftRecordDao
import com.example.aleartmycontroller.data.local.dao.AmcOutboxDao
import com.example.aleartmycontroller.data.local.dao.AmcRecordRevisionDao
import com.example.aleartmycontroller.data.local.dao.AnalyticsDao
import com.example.aleartmycontroller.data.local.dao.EventDao
import com.example.aleartmycontroller.data.local.dao.MemoDao
import com.example.aleartmycontroller.data.local.dao.ObservationEventDao
import com.example.aleartmycontroller.data.local.dao.PhotoDao
import com.example.aleartmycontroller.data.local.dao.RecordDao
import com.example.aleartmycontroller.data.local.dao.TogglPendingActionDao
import com.example.aleartmycontroller.data.local.dao.TogglSyncStateDao
import com.example.aleartmycontroller.data.local.dao.TogglTimeEntryCacheDao
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {

    @Provides
    @Singleton
    fun provideDatabase(@ApplicationContext context: Context): AppDatabase =
        Room.databaseBuilder(context, AppDatabase::class.java, AppDatabase.DATABASE_NAME)
            .addMigrations(
                AppDatabase.MIGRATION_1_2,
                AppDatabase.MIGRATION_2_3,
                AppDatabase.MIGRATION_3_4,
                AppDatabase.MIGRATION_4_5,
                AppDatabase.MIGRATION_5_6,
                AppDatabase.MIGRATION_6_7
            )
            .apply {
                if (BuildConfig.DEBUG) {
                    fallbackToDestructiveMigrationOnDowngrade()
                }
            }
            .build()

    @Provides fun provideAnalyticsDao(db: AppDatabase): AnalyticsDao           = db.analyticsDao()
    @Provides fun provideAmcDraftRecordDao(db: AppDatabase): AmcDraftRecordDao = db.amcDraftRecordDao()
    @Provides fun provideAmcRecordRevisionDao(db: AppDatabase): AmcRecordRevisionDao = db.amcRecordRevisionDao()
    @Provides fun provideAmcAttachmentQueueDao(db: AppDatabase): AmcAttachmentQueueDao = db.amcAttachmentQueueDao()
    @Provides fun provideAmcOutboxDao(db: AppDatabase): AmcOutboxDao = db.amcOutboxDao()
    @Provides fun provideEventDao(db: AppDatabase): EventDao                   = db.eventDao()
    @Provides fun provideObservationEventDao(db: AppDatabase): ObservationEventDao = db.observationEventDao()
    @Provides fun provideRecordDao(db: AppDatabase): RecordDao                 = db.recordDao()
    @Provides fun providePhotoDao(db: AppDatabase): PhotoDao                   = db.photoDao()
    @Provides fun provideMemoDao(db: AppDatabase): MemoDao                     = db.memoDao()
    @Provides fun provideTogglSyncStateDao(db: AppDatabase): TogglSyncStateDao = db.togglSyncStateDao()
    @Provides fun provideTogglPendingActionDao(db: AppDatabase): TogglPendingActionDao = db.togglPendingActionDao()
    @Provides fun provideTogglTimeEntryCacheDao(db: AppDatabase): TogglTimeEntryCacheDao = db.togglTimeEntryCacheDao()
}

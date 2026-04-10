package com.example.aleartmycontroller.di

import android.content.Context
import androidx.room.Room
import com.example.aleartmycontroller.data.local.AppDatabase
import com.example.aleartmycontroller.data.local.dao.AnalyticsDao
import com.example.aleartmycontroller.data.local.dao.EventDao
import com.example.aleartmycontroller.data.local.dao.MemoDao
import com.example.aleartmycontroller.data.local.dao.PhotoDao
import com.example.aleartmycontroller.data.local.dao.RecordDao
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
            .addMigrations(AppDatabase.MIGRATION_1_2, AppDatabase.MIGRATION_2_3)
            .build()

    @Provides fun provideAnalyticsDao(db: AppDatabase): AnalyticsDao = db.analyticsDao()
    @Provides fun provideEventDao(db: AppDatabase): EventDao   = db.eventDao()
    @Provides fun provideRecordDao(db: AppDatabase): RecordDao = db.recordDao()
    @Provides fun providePhotoDao(db: AppDatabase): PhotoDao   = db.photoDao()
    @Provides fun provideMemoDao(db: AppDatabase): MemoDao     = db.memoDao()
}

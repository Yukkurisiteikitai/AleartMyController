package com.example.aleartmycontroller

import android.app.Application
import dagger.hilt.android.HiltAndroidApp

/**
 * Hilt を有効化するための Application クラス。
 * @HiltAndroidApp によって Hilt のコードが生成される。
 */
import androidx.hilt.work.HiltWorkerFactory
import androidx.work.Configuration
import com.example.aleartmycontroller.ui.util.NotificationHelper
import javax.inject.Inject

@HiltAndroidApp
class AleartApplication : Application(), Configuration.Provider {

    @Inject
    lateinit var workerFactory: HiltWorkerFactory

    override val workManagerConfiguration: Configuration
        get() = Configuration.Builder()
            .setWorkerFactory(workerFactory)
            .build()

    override fun onCreate() {
        super.onCreate()
        NotificationHelper.createNotificationChannel(this)
    }
}

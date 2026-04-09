package com.example.aleartmycontroller

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.example.aleartmycontroller.ui.navigation.AppNavHost
import com.example.aleartmycontroller.ui.theme.AleartMyControllerTheme
import dagger.hilt.android.AndroidEntryPoint

/**
 * アプリのエントリーポイント。
 * @AndroidEntryPoint で Hilt による DI を有効化する。
 */
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // §6, §7: リマインダー通知ワーカーのスケジュール (15分間隔)
        val reminderRequest = PeriodicWorkRequestBuilder<com.example.aleartmycontroller.worker.ObservationReminderWorker>(
            15, TimeUnit.MINUTES
        ).build()
        
        WorkManager.getInstance(this).enqueueUniquePeriodicWork(
            "ObservationReminder",
            ExistingPeriodicWorkPolicy.KEEP,
            reminderRequest
        )

        // 通知タップ時の eventId 取得
        val eventIdExtra = intent.getLongExtra("eventId", -1L)
        val initialEventId = if (eventIdExtra != -1L) eventIdExtra else null

        enableEdgeToEdge()
        setContent {
            AleartMyControllerTheme {
                AppNavHost(initialEventId = initialEventId)
            }
        }
    }
}
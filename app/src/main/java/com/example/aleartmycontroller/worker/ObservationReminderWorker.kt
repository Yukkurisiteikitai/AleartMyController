package com.example.aleartmycontroller.worker

import android.content.Context
import androidx.hilt.work.HiltWorker
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.example.aleartmycontroller.data.repository.EventRepository
import com.example.aleartmycontroller.ui.util.NotificationHelper
import dagger.assisted.Assisted
import dagger.assisted.AssistedInject
import android.util.Log

/**
 * §6, §7: WorkManager ワーカー
 * インターバル周期で起動し、現在進行中のイベントを確認→観察リマインダー通知を発行する。
 */
@HiltWorker
class ObservationReminderWorker @AssistedInject constructor(
    @Assisted appContext: Context,
    @Assisted workerParams: WorkerParameters,
    private val eventRepository: EventRepository
) : CoroutineWorker(appContext, workerParams) {

    companion object {
        const val TAG = "ObservationReminder"
    }

    override suspend fun doWork(): Result {
        return runCatching {
            val nowMillis = System.currentTimeMillis()

            // 今まさに進行中のイベントを全件から探す
            val upcomingList = mutableListOf<com.example.aleartmycontroller.data.local.entity.EventEntity>()
            // observeUpcomingEvents は Flow なので、1回だけ取得するために firstOrNull を使う
            val allEvents = eventRepository.getUpcomingEventsOnce()
            val ongoingEvents = allEvents.filter { it.startTime <= nowMillis && it.endTime > nowMillis }

            if (ongoingEvents.isEmpty()) {
                Log.d(TAG, "No ongoing events — skipping notification.")
                return@runCatching
            }

            ongoingEvents.forEach { event ->
                NotificationHelper.showReminderNotification(
                    context = applicationContext,
                    eventId = event.eventId,
                    title = "観察記録のタイミングです",
                    content = event.title
                )
            }
        }
            .onFailure { Log.e(TAG, "Worker failed", it) }
            .let { if (it.isSuccess) Result.success() else Result.retry() }
    }
}

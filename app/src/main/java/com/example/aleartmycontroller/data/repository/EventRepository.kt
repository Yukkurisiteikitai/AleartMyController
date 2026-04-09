package com.example.aleartmycontroller.data.repository

import com.example.aleartmycontroller.BuildConfig
import com.example.aleartmycontroller.data.local.dao.EventDao
import com.example.aleartmycontroller.data.local.entity.EventEntity
import com.example.aleartmycontroller.data.remote.google.GoogleCalendarApi
import kotlinx.coroutines.flow.Flow
import java.time.OffsetDateTime
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class EventRepository @Inject constructor(
    private val eventDao: EventDao,
    private val calendarApi: GoogleCalendarApi
) {
    private val isoFormatter: DateTimeFormatter = DateTimeFormatter.ISO_OFFSET_DATE_TIME

    /** 今日以降のイベントをFlowで監視（ローカルDB） */
    fun observeUpcomingEvents(): Flow<List<EventEntity>> {
        val nowMillis = System.currentTimeMillis()
        return eventDao.observeUpcoming(nowMillis)
    }

    /** WorkManager など一度だけ取得する場合に使用する */
    suspend fun getUpcomingEventsOnce(): List<EventEntity> {
        return eventDao.getUpcoming(System.currentTimeMillis())
    }

    /** 全イベントを監視（履歴画面向け） */
    fun observeAllEvents(): Flow<List<EventEntity>> = eventDao.observeAll()

    /**
     * Google Calendar APIから今日〜7日後のイベントを取得しDBへ同期する。
     * 古いキャッシュは削除する。
     */
    suspend fun syncFromCalendar() {
        val now = OffsetDateTime.now(ZoneId.systemDefault())
        val weekLater = now.plusDays(7)

        val response = calendarApi.listEvents(
            timeMin = now.format(isoFormatter),
            timeMax = weekLater.format(isoFormatter)
        )

        val entities = response.items.map { item ->
            val startMillis = OffsetDateTime.parse(item.start.value, isoFormatter)
                .toInstant().toEpochMilli()
            val endMillis = OffsetDateTime.parse(item.end.value, isoFormatter)
                .toInstant().toEpochMilli()
            EventEntity(
                googleEventId = item.id,
                title = item.summary ?: "(無題)",
                startTime = startMillis,
                endTime = endMillis
            )
        }

        // DB に upsert してから不要なエントリを削除
        eventDao.upsertAll(entities)
        val activeIds = entities.map { it.googleEventId }
        if (activeIds.isNotEmpty()) {
            eventDao.deleteStaleEvents(activeIds)
        }
    }

    suspend fun findById(id: Long): EventEntity? = eventDao.findById(id)
}

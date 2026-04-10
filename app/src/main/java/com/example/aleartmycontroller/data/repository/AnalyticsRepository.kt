package com.example.aleartmycontroller.data.repository

import com.example.aleartmycontroller.data.local.dao.AnalyticsDao
import com.example.aleartmycontroller.data.local.dao.DailyRecordCount
import com.example.aleartmycontroller.data.local.dao.EventRecordCount
import com.example.aleartmycontroller.data.local.dao.RecordTypeCount
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import javax.inject.Inject
import javax.inject.Singleton

data class AnalyticsSummary(
    val totalCount: Int,
    val photoCount: Int,
    val memoCount: Int
)

data class TogglDailyDuration(
    val dayKey: Long,       // LocalDate.toEpochDay()
    val totalSeconds: Long
)

@Singleton
class AnalyticsRepository @Inject constructor(
    private val analyticsDao: AnalyticsDao,
    private val togglRepository: TogglRepository
) {
    private val dateFormatter = DateTimeFormatter.ISO_LOCAL_DATE
    private val zoneId = ZoneId.systemDefault()

    suspend fun getSummary(fromMillis: Long): AnalyticsSummary {
        return AnalyticsSummary(
            totalCount = analyticsDao.getTotalCount(fromMillis),
            photoCount = analyticsDao.getPhotoCount(fromMillis),
            memoCount = analyticsDao.getMemoCount(fromMillis)
        )
    }

    suspend fun getDailyRecordCounts(fromMillis: Long): List<DailyRecordCount> {
        return analyticsDao.getDailyRecordCounts(fromMillis)
    }

    suspend fun getRecordTypeBreakdown(fromMillis: Long): List<RecordTypeCount> {
        return analyticsDao.getRecordTypeBreakdown(fromMillis)
    }

    suspend fun getTopEvents(fromMillis: Long): List<EventRecordCount> {
        return analyticsDao.getTopEventsByRecordCount(fromMillis)
    }

    suspend fun getTogglDailyDurations(fromMillis: Long): List<TogglDailyDuration> {
        val startDate = Instant.ofEpochMilli(fromMillis)
            .atZone(zoneId).toLocalDate()
            .format(dateFormatter)
        val endDate = LocalDate.now().format(dateFormatter)
        val entries = togglRepository.getEntriesForRange(startDate, endDate)
        return entries
            .filter { it.duration > 0 }
            .mapNotNull { entry ->
                runCatching {
                    val date = Instant.parse(entry.start).atZone(zoneId).toLocalDate()
                    date.toEpochDay() to entry.duration
                }.getOrNull()
            }
            .groupBy { it.first }
            .map { (dayEpoch, pairs) ->
                TogglDailyDuration(dayKey = dayEpoch, totalSeconds = pairs.sumOf { it.second })
            }
            .sortedBy { it.dayKey }
    }
}

package com.example.aleartmycontroller.data.local.dao

import androidx.room.Dao
import androidx.room.Query

// ---- 集計結果データクラス ----

data class DailyRecordCount(
    val dayKey: Long,       // epoch_millis / 86400000 (UTC日キー)
    val totalCount: Int,
    val photoCount: Int,
    val memoCount: Int
)

data class RecordTypeCount(
    val recordType: String, // "PHOTO" or "MEMO"
    val count: Int
)

data class EventRecordCount(
    val eventTitle: String,
    val recordCount: Int
)

// ---- DAO ----

@Dao
interface AnalyticsDao {

    @Query("SELECT COUNT(*) FROM records WHERE recordTime >= :fromMillis")
    suspend fun getTotalCount(fromMillis: Long): Int

    @Query("SELECT COUNT(*) FROM records WHERE recordTime >= :fromMillis AND recordType = 'PHOTO'")
    suspend fun getPhotoCount(fromMillis: Long): Int

    @Query("SELECT COUNT(*) FROM records WHERE recordTime >= :fromMillis AND recordType = 'MEMO'")
    suspend fun getMemoCount(fromMillis: Long): Int

    @Query("""
        SELECT (recordTime / 86400000) AS dayKey,
               COUNT(*) AS totalCount,
               SUM(CASE WHEN recordType = 'PHOTO' THEN 1 ELSE 0 END) AS photoCount,
               SUM(CASE WHEN recordType = 'MEMO'  THEN 1 ELSE 0 END) AS memoCount
        FROM records
        WHERE recordTime >= :fromMillis
        GROUP BY dayKey
        ORDER BY dayKey ASC
    """)
    suspend fun getDailyRecordCounts(fromMillis: Long): List<DailyRecordCount>

    @Query("""
        SELECT recordType, COUNT(*) AS count
        FROM records
        WHERE recordTime >= :fromMillis
        GROUP BY recordType
    """)
    suspend fun getRecordTypeBreakdown(fromMillis: Long): List<RecordTypeCount>

    @Query("""
        SELECT e.title AS eventTitle, COUNT(r.recordId) AS recordCount
        FROM records r
        INNER JOIN events e ON r.eventId = e.eventId
        WHERE r.recordTime >= :fromMillis
        GROUP BY r.eventId
        ORDER BY recordCount DESC
        LIMIT 10
    """)
    suspend fun getTopEventsByRecordCount(fromMillis: Long): List<EventRecordCount>
}

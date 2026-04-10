package com.example.aleartmycontroller.data.local.dao

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Transaction
import com.example.aleartmycontroller.data.local.entity.RecordEntity
import com.example.aleartmycontroller.data.local.entity.RecordType
import com.example.aleartmycontroller.data.local.entity.RecordWithAttachments
import kotlinx.coroutines.flow.Flow

@Dao
interface RecordDao {

    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insert(record: RecordEntity): Long

    @Delete
    suspend fun delete(record: RecordEntity)

    /**
     * カレンダーイベントに紐づく記録を時刻順で監視。
     * events → observation_events → records の JOIN で解決するため、
     * 呼び出し側は引き続き EventEntity.eventId を渡せる。
     */
    @Query("""
        SELECT r.* FROM records r
        INNER JOIN observation_events oe ON r.obsEventId = oe.obsEventId
        INNER JOIN events e ON e.googleEventId = oe.googleEventId
        WHERE e.eventId = :eventId
        ORDER BY r.recordTime ASC
    """)
    fun observeByEvent(eventId: Long): Flow<List<RecordEntity>>

    /** イベントに紐づく記録を時刻順で監視（添付ファイル込み） */
    @Transaction
    @Query("""
        SELECT r.* FROM records r
        INNER JOIN observation_events oe ON r.obsEventId = oe.obsEventId
        INNER JOIN events e ON e.googleEventId = oe.googleEventId
        WHERE e.eventId = :eventId
        ORDER BY r.recordTime ASC
    """)
    fun observeByEventWithAttachments(eventId: Long): Flow<List<RecordWithAttachments>>

    /** すべての記録を最新順で監視（全履歴表示用） */
    @Query("SELECT * FROM records ORDER BY recordTime DESC")
    fun observeAll(): Flow<List<RecordEntity>>

    /** すべての記録を最新順で監視（添付ファイル込み） */
    @Transaction
    @Query("SELECT * FROM records ORDER BY recordTime DESC")
    fun observeAllWithAttachments(): Flow<List<RecordWithAttachments>>

    @Query("SELECT * FROM records WHERE recordId = :id")
    suspend fun findById(id: Long): RecordEntity?

    /** イベントごとの記録数（写真・メモ別） */
    @Query("""
        SELECT COUNT(*) FROM records r
        INNER JOIN observation_events oe ON r.obsEventId = oe.obsEventId
        INNER JOIN events e ON e.googleEventId = oe.googleEventId
        WHERE e.eventId = :eventId AND r.recordType = :type
    """)
    suspend fun countByType(eventId: Long, type: RecordType): Int

    /**
     * 写真・メモの件数を一括取得（イベント一覧のバッジ表示用）。
     * events → observation_events JOIN で解決するため、呼び出し側は EventEntity.eventId のリストを渡せる。
     * RecordCountResult の eventId フィールドは EventEntity.eventId に対応する。
     */
    @Query("""
        SELECT e.eventId,
               SUM(CASE WHEN r.recordType = 'PHOTO' THEN 1 ELSE 0 END) AS photoCount,
               SUM(CASE WHEN r.recordType = 'MEMO'  THEN 1 ELSE 0 END) AS memoCount
        FROM events e
        LEFT JOIN observation_events oe ON oe.googleEventId = e.googleEventId
        LEFT JOIN records r ON r.obsEventId = oe.obsEventId
        WHERE e.eventId IN (:eventIds)
        GROUP BY e.eventId
    """)
    suspend fun countByEvents(eventIds: List<Long>): List<RecordCountResult>
}

/** イベント一覧でのバッジ表示用集計結果 */
data class RecordCountResult(
    val eventId: Long,
    val photoCount: Int,
    val memoCount: Int
)

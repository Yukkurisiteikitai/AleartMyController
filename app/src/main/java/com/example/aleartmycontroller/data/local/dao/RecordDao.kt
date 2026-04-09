package com.example.aleartmycontroller.data.local.dao

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.example.aleartmycontroller.data.local.entity.RecordEntity
import com.example.aleartmycontroller.data.local.entity.RecordType
import kotlinx.coroutines.flow.Flow

@Dao
interface RecordDao {

    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insert(record: RecordEntity): Long

    @Delete
    suspend fun delete(record: RecordEntity)

    /** イベントに紐づく記録を時刻順で監視 */
    @Query("SELECT * FROM records WHERE eventId = :eventId ORDER BY recordTime ASC")
    fun observeByEvent(eventId: Long): Flow<List<RecordEntity>>

    @Query("SELECT * FROM records WHERE recordId = :id")
    suspend fun findById(id: Long): RecordEntity?

    /** イベントごとの記録数（写真・メモ別） */
    @Query("SELECT COUNT(*) FROM records WHERE eventId = :eventId AND recordType = :type")
    suspend fun countByType(eventId: Long, type: RecordType): Int

    /** 写真記録の合計数（イベント一覧表示用） */
    @Query(
        """
        SELECT r.eventId, 
               SUM(CASE WHEN r.recordType = 'PHOTO' THEN 1 ELSE 0 END) AS photoCount,
               SUM(CASE WHEN r.recordType = 'MEMO'  THEN 1 ELSE 0 END) AS memoCount
        FROM records r
        WHERE r.eventId IN (:eventIds)
        GROUP BY r.eventId
        """
    )
    suspend fun countByEvents(eventIds: List<Long>): List<RecordCountResult>
}

/** イベント一覧でのバッジ表示用集計結果 */
data class RecordCountResult(
    val eventId: Long,
    val photoCount: Int,
    val memoCount: Int
)

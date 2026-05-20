package com.example.aleartmycontroller.data.local.dao

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import com.example.aleartmycontroller.data.local.entity.EventEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface EventDao {

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertAll(events: List<EventEntity>)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(event: EventEntity): Long

    @Update
    suspend fun update(event: EventEntity)

    @Delete
    suspend fun delete(event: EventEntity)

    /** 今日以降のイベントを開始時刻順で返す */
    @Query("SELECT * FROM events WHERE startTime >= :fromMillis ORDER BY startTime ASC")
    fun observeUpcoming(fromMillis: Long): Flow<List<EventEntity>>

    @Query("SELECT * FROM events WHERE startTime >= :fromMillis ORDER BY startTime ASC")
    suspend fun getUpcoming(fromMillis: Long): List<EventEntity>

    /** 全イベントを開始時刻降順（履歴用） */
    @Query("SELECT * FROM events ORDER BY startTime DESC")
    fun observeAll(): Flow<List<EventEntity>>

    @Query("SELECT * FROM events WHERE eventId = :id")
    suspend fun findById(id: Long): EventEntity?

    @Query("SELECT * FROM events WHERE googleEventId = :googleId")
    suspend fun findByGoogleId(googleId: String): EventEntity?

    /** 現在時刻に進行中のイベントを取得する */
    @Query("SELECT * FROM events WHERE startTime <= :now AND endTime > :now LIMIT 1")
    suspend fun findOngoing(now: Long): EventEntity?

    @Query("SELECT * FROM events WHERE startTime <= :now AND endTime > :now ORDER BY startTime DESC LIMIT 1")
    fun observeOngoing(now: Long): Flow<EventEntity?>

    /** 古いキャッシュを削除（同期時に使用） */
    @Query("""
        DELETE FROM events
        WHERE googleEventId NOT LIKE 'local-draft:%'
          AND googleEventId NOT IN (:activeGoogleIds)
    """)
    suspend fun deleteStaleEvents(activeGoogleIds: List<String>)
}

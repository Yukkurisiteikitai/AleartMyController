package com.example.aleartmycontroller.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.example.aleartmycontroller.data.local.entity.TogglTimeEntryCacheEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface TogglTimeEntryCacheDao {

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertAll(entries: List<TogglTimeEntryCacheEntity>)

    @Query("""
        SELECT * FROM toggl_time_entry_cache
        WHERE startMillis >= :fromMillis AND startMillis <= :toMillis
        ORDER BY startMillis ASC
    """)
    suspend fun getBetween(fromMillis: Long, toMillis: Long): List<TogglTimeEntryCacheEntity>

    @Query("""
        SELECT * FROM toggl_time_entry_cache
        WHERE startMillis >= :fromMillis AND startMillis <= :toMillis
        ORDER BY startMillis ASC
    """)
    fun observeBetween(fromMillis: Long, toMillis: Long): Flow<List<TogglTimeEntryCacheEntity>>

    @Query("DELETE FROM toggl_time_entry_cache WHERE startMillis < :cutoffMillis")
    suspend fun deleteOlderThan(cutoffMillis: Long)
}

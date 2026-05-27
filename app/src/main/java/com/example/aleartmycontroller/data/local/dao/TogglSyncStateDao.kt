package com.example.aleartmycontroller.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.example.aleartmycontroller.data.local.entity.TogglSyncStateEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface TogglSyncStateDao {

    @Query("SELECT * FROM toggl_sync_state WHERE id = :id LIMIT 1")
    fun observeState(id: Int = TogglSyncStateEntity.SINGLETON_ID): Flow<TogglSyncStateEntity?>

    @Query("SELECT * FROM toggl_sync_state WHERE id = :id LIMIT 1")
    suspend fun getState(id: Int = TogglSyncStateEntity.SINGLETON_ID): TogglSyncStateEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(state: TogglSyncStateEntity)
}

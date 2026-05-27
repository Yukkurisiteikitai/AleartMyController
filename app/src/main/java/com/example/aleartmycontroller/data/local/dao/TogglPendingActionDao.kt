package com.example.aleartmycontroller.data.local.dao

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.example.aleartmycontroller.data.local.entity.TogglPendingActionEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface TogglPendingActionDao {

    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insert(action: TogglPendingActionEntity): Long

    @Query("SELECT * FROM toggl_pending_actions ORDER BY createdAtMillis ASC, actionId ASC")
    suspend fun getAllPending(): List<TogglPendingActionEntity>

    @Query("SELECT COUNT(*) FROM toggl_pending_actions")
    fun observePendingCount(): Flow<Int>

    @Query("SELECT EXISTS(SELECT 1 FROM toggl_pending_actions WHERE actionType = :actionType)")
    suspend fun hasActionType(actionType: String): Boolean

    @Delete
    suspend fun delete(action: TogglPendingActionEntity)

    @Query("UPDATE toggl_pending_actions SET attemptCount = :attemptCount, lastAttemptAtMillis = :lastAttemptAtMillis, lastErrorMessage = :lastErrorMessage WHERE actionId = :actionId")
    suspend fun markFailed(
        actionId: Long,
        attemptCount: Int,
        lastAttemptAtMillis: Long,
        lastErrorMessage: String
    )

    @Query("DELETE FROM toggl_pending_actions WHERE actionId = :actionId")
    suspend fun deleteById(actionId: Long)

    @Query("DELETE FROM toggl_pending_actions")
    suspend fun deleteAll()
}

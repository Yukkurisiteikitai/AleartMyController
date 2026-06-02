package com.example.aleartmycontroller.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.example.aleartmycontroller.data.local.entity.amc.AmcOutboxEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface AmcOutboxDao {
    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insert(job: AmcOutboxEntity): Long

    @Query("SELECT * FROM amc_outbox_jobs WHERE jobId = :jobId LIMIT 1")
    suspend fun findById(jobId: Long): AmcOutboxEntity?

    @Query("SELECT * FROM amc_outbox_jobs WHERE idempotencyKey = :idempotencyKey LIMIT 1")
    suspend fun findByIdempotencyKey(idempotencyKey: String): AmcOutboxEntity?

    @Query("SELECT * FROM amc_outbox_jobs WHERE state IN ('PENDING', 'FAILED') ORDER BY nextAttemptAtMillis ASC, updatedAtMillis ASC")
    fun observePendingJobs(): Flow<List<AmcOutboxEntity>>

    @Query(
        """
        UPDATE amc_outbox_jobs
        SET state = :state,
            attemptCount = :attemptCount,
            nextAttemptAtMillis = :nextAttemptAtMillis,
            lastErrorMessage = :lastErrorMessage,
            updatedAtMillis = :updatedAtMillis
        WHERE jobId = :jobId
        """
    )
    suspend fun updateState(
        jobId: Long,
        state: String,
        attemptCount: Int,
        nextAttemptAtMillis: Long,
        lastErrorMessage: String? = null,
        updatedAtMillis: Long
    )
}


package com.example.aleartmycontroller.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.example.aleartmycontroller.data.local.entity.amc.AmcAttachmentQueueEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface AmcAttachmentQueueDao {
    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insert(attachment: AmcAttachmentQueueEntity): Long

    @Query("SELECT * FROM amc_attachment_queue WHERE attachmentId = :attachmentId LIMIT 1")
    suspend fun findById(attachmentId: Long): AmcAttachmentQueueEntity?

    @Query("SELECT * FROM amc_attachment_queue WHERE idempotencyKey = :idempotencyKey LIMIT 1")
    suspend fun findByIdempotencyKey(idempotencyKey: String): AmcAttachmentQueueEntity?

    @Query("SELECT * FROM amc_attachment_queue WHERE draftRecordId = :draftRecordId ORDER BY createdAtMillis ASC")
    fun observeByDraftRecordId(draftRecordId: Long): Flow<List<AmcAttachmentQueueEntity>>

    @Query("SELECT * FROM amc_attachment_queue WHERE status IN ('PENDING', 'FAILED') ORDER BY updatedAtMillis ASC")
    fun observePendingUploads(): Flow<List<AmcAttachmentQueueEntity>>

    @Query(
        """
        UPDATE amc_attachment_queue
        SET status = :status,
            r2Key = :r2Key,
            lastErrorMessage = :lastErrorMessage,
            retryCount = :retryCount,
            uploadedAtMillis = :uploadedAtMillis,
            readyAtMillis = :readyAtMillis,
            updatedAtMillis = :updatedAtMillis
        WHERE attachmentId = :attachmentId
        """
    )
    suspend fun updateStatus(
        attachmentId: Long,
        status: String,
        r2Key: String? = null,
        lastErrorMessage: String? = null,
        retryCount: Int,
        uploadedAtMillis: Long? = null,
        readyAtMillis: Long? = null,
        updatedAtMillis: Long
    )
}


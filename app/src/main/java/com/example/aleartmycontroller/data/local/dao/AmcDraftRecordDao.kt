package com.example.aleartmycontroller.data.local.dao

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.example.aleartmycontroller.data.local.entity.amc.AmcDraftRecordEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface AmcDraftRecordDao {
    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insert(record: AmcDraftRecordEntity): Long

    @Delete
    suspend fun delete(record: AmcDraftRecordEntity)

    @Query("SELECT * FROM amc_draft_records WHERE draftRecordId = :id LIMIT 1")
    suspend fun findById(id: Long): AmcDraftRecordEntity?

    @Query("SELECT * FROM amc_draft_records WHERE remoteRecordId = :remoteRecordId LIMIT 1")
    suspend fun findByRemoteRecordId(remoteRecordId: String): AmcDraftRecordEntity?

    @Query("SELECT * FROM amc_draft_records WHERE idempotencyKey = :idempotencyKey LIMIT 1")
    suspend fun findByIdempotencyKey(idempotencyKey: String): AmcDraftRecordEntity?

    @Query("SELECT * FROM amc_draft_records ORDER BY updatedAtMillis DESC")
    fun observeAll(): Flow<List<AmcDraftRecordEntity>>

    @Query("SELECT * FROM amc_draft_records WHERE syncState != 'SYNCED' ORDER BY updatedAtMillis DESC")
    fun observePending(): Flow<List<AmcDraftRecordEntity>>

    @Query("SELECT COUNT(*) FROM amc_draft_records WHERE syncState != 'SYNCED'")
    fun observePendingCount(): Flow<Int>

    @Query(
        """
        UPDATE amc_draft_records
        SET currentBody = :currentBody,
            currentRevision = :currentRevision,
            updatedAtMillis = :updatedAtMillis,
            syncState = :syncState
        WHERE draftRecordId = :draftRecordId
        """
    )
    suspend fun updateCurrentBody(
        draftRecordId: Long,
        currentBody: String,
        currentRevision: Int,
        updatedAtMillis: Long,
        syncState: String
    )

    @Query(
        """
        UPDATE amc_draft_records
        SET remoteRecordId = :remoteRecordId,
            updatedAtMillis = :updatedAtMillis,
            syncState = :syncState
        WHERE draftRecordId = :draftRecordId
        """
    )
    suspend fun markSynced(
        draftRecordId: Long,
        remoteRecordId: String,
        updatedAtMillis: Long,
        syncState: String
    )

    @Query(
        """
        UPDATE amc_draft_records
        SET deletedAtMillis = :deletedAtMillis,
            deletedByUserId = :deletedByUserId,
            updatedAtMillis = :updatedAtMillis,
            syncState = :syncState
        WHERE draftRecordId = :draftRecordId
        """
    )
    suspend fun markDeleted(
        draftRecordId: Long,
        deletedAtMillis: Long,
        deletedByUserId: String?,
        updatedAtMillis: Long,
        syncState: String
    )
}


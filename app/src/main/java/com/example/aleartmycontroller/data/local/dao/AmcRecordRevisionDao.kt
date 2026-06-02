package com.example.aleartmycontroller.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.example.aleartmycontroller.data.local.entity.amc.AmcRecordRevisionEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface AmcRecordRevisionDao {
    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insert(revision: AmcRecordRevisionEntity): Long

    @Query("SELECT * FROM amc_record_revisions WHERE draftRecordId = :draftRecordId ORDER BY revisionNumber ASC")
    fun observeByDraftRecordId(draftRecordId: Long): Flow<List<AmcRecordRevisionEntity>>

    @Query("SELECT * FROM amc_record_revisions WHERE draftRecordId = :draftRecordId ORDER BY revisionNumber DESC LIMIT 1")
    suspend fun findLatestForDraft(draftRecordId: Long): AmcRecordRevisionEntity?

    @Query("SELECT * FROM amc_record_revisions WHERE idempotencyKey = :idempotencyKey LIMIT 1")
    suspend fun findByIdempotencyKey(idempotencyKey: String): AmcRecordRevisionEntity?

    @Query("SELECT MAX(revisionNumber) FROM amc_record_revisions WHERE draftRecordId = :draftRecordId")
    suspend fun findLatestRevisionNumber(draftRecordId: Long): Int?
}


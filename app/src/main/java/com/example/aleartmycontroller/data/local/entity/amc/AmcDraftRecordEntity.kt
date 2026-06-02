package com.example.aleartmycontroller.data.local.entity.amc

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey
import com.example.aleartmycontroller.data.amc.AmcSource
import com.example.aleartmycontroller.data.amc.AmcSyncState
import com.example.aleartmycontroller.data.amc.AmcVisibility

@Entity(
    tableName = "amc_draft_records",
    indices = [
        Index(value = ["remoteRecordId"], unique = true),
        Index(value = ["idempotencyKey"], unique = true),
        Index("eventId"),
        Index("syncState")
    ]
)
data class AmcDraftRecordEntity(
    @PrimaryKey(autoGenerate = true) val draftRecordId: Long = 0,
    val eventId: Long? = null,
    val remoteRecordId: String? = null,
    val ownerUserId: String? = null,
    val currentBody: String,
    val visibility: AmcVisibility,
    val currentRevision: Int = 1,
    val updatedAtMillis: Long,
    val createdAtMillis: Long,
    val deletedAtMillis: Long? = null,
    val deletedByUserId: String? = null,
    val source: AmcSource = AmcSource.LOCAL_DRAFT,
    val syncState: AmcSyncState = AmcSyncState.DRAFT,
    val idempotencyKey: String
)


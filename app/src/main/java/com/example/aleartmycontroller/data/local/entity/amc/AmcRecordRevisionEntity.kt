package com.example.aleartmycontroller.data.local.entity.amc

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "amc_record_revisions",
    indices = [
        Index("draftRecordId"),
        Index(value = ["idempotencyKey"], unique = true),
        Index(value = ["draftRecordId", "revisionNumber"], unique = true)
    ]
)
data class AmcRecordRevisionEntity(
    @PrimaryKey(autoGenerate = true) val revisionId: Long = 0,
    val draftRecordId: Long,
    val revisionNumber: Int,
    val bodySnapshot: String,
    val editorUserId: String? = null,
    val changeSummary: String? = null,
    val createdAtMillis: Long,
    val idempotencyKey: String
)


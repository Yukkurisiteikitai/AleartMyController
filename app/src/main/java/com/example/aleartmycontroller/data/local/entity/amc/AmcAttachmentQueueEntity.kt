package com.example.aleartmycontroller.data.local.entity.amc

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey
import com.example.aleartmycontroller.data.amc.AmcAttachmentStatus
import com.example.aleartmycontroller.data.amc.AmcAttachmentType

@Entity(
    tableName = "amc_attachment_queue",
    indices = [
        Index("draftRecordId"),
        Index("status"),
        Index(value = ["idempotencyKey"], unique = true)
    ]
)
data class AmcAttachmentQueueEntity(
    @PrimaryKey(autoGenerate = true) val attachmentId: Long = 0,
    val draftRecordId: Long,
    val type: AmcAttachmentType,
    val localUri: String,
    val storagePath: String? = null,
    val mimeType: String,
    val sizeBytes: Long,
    val checksum: String? = null,
    val status: AmcAttachmentStatus = AmcAttachmentStatus.PENDING,
    val uploadSessionId: String? = null,
    val attemptNumber: Int = 0,
    val retryCount: Int = 0,
    val lastErrorCode: String? = null,
    val lastErrorMessage: String? = null,
    val expiresAtMillis: Long? = null,
    val uploadedAtMillis: Long? = null,
    val readyAtMillis: Long? = null,
    val createdAtMillis: Long,
    val updatedAtMillis: Long,
    val idempotencyKey: String
)

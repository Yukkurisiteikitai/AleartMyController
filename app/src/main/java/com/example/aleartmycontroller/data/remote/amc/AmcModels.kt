package com.example.aleartmycontroller.data.remote.amc

import com.example.aleartmycontroller.data.amc.AmcAttachmentType
import com.example.aleartmycontroller.data.amc.AmcVisibility

data class AmcRecordInitRequest(
    val eventId: Long?,
    val ownerUserId: String?,
    val visibility: AmcVisibility,
    val currentBody: String,
    val idempotencyKey: String,
    val source: String
)

data class AmcRecordInitResponse(
    val recordId: String,
    val currentRevision: Int,
    val currentBody: String,
    val updatedAtMillis: Long
)

data class AmcRecordUpsertRequest(
    val currentRevision: Int,
    val currentBody: String,
    val updatedAtMillis: Long,
    val idempotencyKey: String
)

data class AmcRecordResponse(
    val recordId: String,
    val currentRevision: Int,
    val currentBody: String,
    val updatedAtMillis: Long,
    val deletedAtMillis: Long? = null,
    val deletedBy: String? = null
)

data class AmcRecordRevisionCreateRequest(
    val currentRevision: Int,
    val bodySnapshot: String,
    val editorUserId: String?,
    val changeSummary: String? = null,
    val idempotencyKey: String
)

data class AmcRecordRevisionResponse(
    val revisionId: String,
    val revisionNumber: Int,
    val createdAtMillis: Long
)

data class AmcAttachmentInitRequest(
    val type: AmcAttachmentType,
    val fileName: String,
    val mimeType: String,
    val sizeBytes: Long,
    val checksum: String? = null,
    val idempotencyKey: String
)

data class AmcAttachmentInitResponse(
    val attachmentId: String,
    val r2Key: String,
    val uploadUrl: String,
    val expiresAtMillis: Long
)

data class AmcAttachmentCompleteRequest(
    val attachmentId: String,
    val r2Key: String,
    val checksum: String? = null
)

data class AmcAttachmentResponse(
    val attachmentId: String,
    val r2Key: String,
    val status: String
)

data class AmcShareResolutionResponse(
    val shareLinkId: String,
    val recordId: String?,
    val canView: Boolean,
    val canEdit: Boolean,
    val isExpired: Boolean,
    val isRevoked: Boolean,
    val currentRevision: Int?,
    val visibility: AmcVisibility?
)

data class AmcRecordAccessResponse(
    val recordId: String,
    val visibility: AmcVisibility,
    val shareStatus: String,
    val revocationStatus: String,
    val expirationMillis: Long?,
    val currentRevision: Int,
    val deleted: Boolean,
    val viewerIsOwner: Boolean
)


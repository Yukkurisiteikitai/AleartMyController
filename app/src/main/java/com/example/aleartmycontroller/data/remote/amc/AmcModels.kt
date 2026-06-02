package com.example.aleartmycontroller.data.remote.amc

import com.example.aleartmycontroller.data.amc.AmcAttachmentType
import com.example.aleartmycontroller.data.amc.AmcAttachmentClientResult
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
    val attachment: AmcAttachmentDescriptor,
    val uploadSessionId: String,
    val attemptNumber: Int,
    val uploadUrl: String,
    val expiresAtMillis: Long,
    val retryable: Boolean
)

data class AmcAttachmentCompleteRequest(
    val attachmentId: String,
    val uploadSessionId: String,
    val attemptNumber: Int,
    val clientResult: AmcAttachmentClientResult,
    val clientErrorCode: String? = null,
    val checksum: String? = null
)

data class AmcAttachmentResponse(
    val attachmentId: String,
    val storagePath: String,
    val status: String
)

data class AmcAttachmentDescriptor(
    val attachmentId: String,
    val storagePath: String,
    val status: String,
    val mimeType: String,
    val sizeBytes: Long,
    val retryCount: Int,
    val attemptNumber: Int,
    val uploadSessionId: String? = null,
    val expiresAtMillis: Long? = null,
    val lastErrorCode: String? = null,
    val lastErrorReason: String? = null
)

data class AmcAttachmentAttemptDescriptor(
    val uploadSessionId: String,
    val attemptNumber: Int,
    val status: String,
    val clientResult: AmcAttachmentClientResult? = null,
    val clientErrorCode: String? = null,
    val serverErrorCode: String? = null,
    val serverErrorReason: String? = null,
    val observedSizeBytes: Long? = null,
    val observedContentType: String? = null,
    val completedAtMillis: Long? = null
)

data class AmcAttachmentCompleteResponse(
    val attachment: AmcAttachmentDescriptor,
    val attempt: AmcAttachmentAttemptDescriptor,
    val verified: Boolean,
    val retryable: Boolean,
    val reason: String? = null
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

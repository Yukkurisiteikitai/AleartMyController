package com.example.aleartmycontroller.data.amc

import android.util.Log
import com.example.aleartmycontroller.data.local.entity.amc.AmcAttachmentQueueEntity
import com.example.aleartmycontroller.data.remote.amc.AmcAttachmentCompleteResponse
import com.example.aleartmycontroller.data.remote.amc.AmcAttachmentInitResponse

internal object AmcAttachmentQueueLogFormatter {
    fun format(
        event: String,
        values: Map<String, Any?>
    ): String {
        val payload = linkedMapOf<String, Any?>("event" to event)
        payload.putAll(values)
        return payload.entries.joinToString(separator = " ") { (key, value) ->
            "$key=${sanitizeValue(key, value)}"
        }
    }

    private fun sanitizeValue(key: String, value: Any?): String {
        if (value == null) return "null"
        return when (key) {
            "localUri" -> sanitizeLocalUri(value.toString())
            "uploadUrl", "authorization", "authHeader", "body" -> "[redacted]"
            "checksum" -> truncate(value.toString(), 8)
            else -> value.toString().replace(' ', '_')
        }
    }

    private fun sanitizeLocalUri(value: String): String {
        val normalized = value.substringAfterLast('/')
        return if (normalized.isBlank()) "[redacted]" else normalized.replace(' ', '_')
    }

    private fun truncate(value: String, maxLength: Int): String {
        return if (value.length <= maxLength) value else value.take(maxLength)
    }
}

object AmcAttachmentQueueLogger {
    private const val TAG = "AMC.AttachmentQueue"

    fun logQueueEvent(
        level: Int,
        event: String,
        attachment: AmcAttachmentQueueEntity,
        previousStatus: AmcAttachmentStatus? = null,
        extra: Map<String, Any?> = emptyMap(),
        throwable: Throwable? = null
    ) {
        log(
            level = level,
            message = AmcAttachmentQueueLogFormatter.format(
                event = event,
                values = linkedMapOf(
                    "attachmentId" to attachment.attachmentId,
                    "draftRecordId" to attachment.draftRecordId,
                    "status" to attachment.status,
                    "previousStatus" to previousStatus,
                    "attemptNumber" to attachment.attemptNumber,
                    "uploadSessionId" to attachment.uploadSessionId,
                    "retryCount" to attachment.retryCount,
                    "errorCode" to attachment.lastErrorCode,
                    "mimeType" to attachment.mimeType,
                    "sizeBytes" to attachment.sizeBytes,
                    "r2Key" to attachment.r2Key,
                    "localUri" to attachment.localUri
                ) + extra
            ),
            throwable = throwable
        )
    }

    fun logApiInitResult(
        recordId: String,
        attachmentId: Long?,
        draftRecordId: Long?,
        response: AmcAttachmentInitResponse,
        httpStatus: Int? = null
    ) {
        log(
            level = Log.INFO,
            message = AmcAttachmentQueueLogFormatter.format(
                event = "api_init_response",
                values = linkedMapOf(
                    "recordId" to recordId,
                    "attachmentId" to attachmentId,
                    "draftRecordId" to draftRecordId,
                    "serverStatus" to response.attachment.status,
                    "attemptNumber" to response.attemptNumber,
                    "uploadSessionId" to response.uploadSessionId,
                    "retryCount" to response.attachment.retryCount,
                    "retryable" to response.retryable,
                    "expiresAtMillis" to response.expiresAtMillis,
                    "reason" to response.attachment.lastErrorReason,
                    "errorCode" to response.attachment.lastErrorCode,
                    "r2Key" to response.attachment.r2Key,
                    "mimeType" to response.attachment.mimeType,
                    "sizeBytes" to response.attachment.sizeBytes,
                    "httpStatus" to httpStatus
                )
            )
        )
    }

    fun logApiCompleteResult(
        recordId: String,
        attachmentId: Long?,
        draftRecordId: Long?,
        response: AmcAttachmentCompleteResponse,
        httpStatus: Int? = null
    ) {
        log(
            level = if (response.verified) Log.INFO else Log.WARN,
            message = AmcAttachmentQueueLogFormatter.format(
                event = "api_complete_response",
                values = linkedMapOf(
                    "recordId" to recordId,
                    "attachmentId" to attachmentId,
                    "draftRecordId" to draftRecordId,
                    "serverStatus" to response.attachment.status,
                    "attemptStatus" to response.attempt.status,
                    "attemptNumber" to response.attempt.attemptNumber,
                    "uploadSessionId" to response.attempt.uploadSessionId,
                    "retryCount" to response.attachment.retryCount,
                    "verified" to response.verified,
                    "retryable" to response.retryable,
                    "reason" to response.reason,
                    "errorCode" to response.attempt.serverErrorCode,
                    "clientErrorCode" to response.attempt.clientErrorCode,
                    "clientResult" to response.attempt.clientResult,
                    "observedSizeBytes" to response.attempt.observedSizeBytes,
                    "observedContentType" to response.attempt.observedContentType,
                    "r2Key" to response.attachment.r2Key,
                    "mimeType" to response.attachment.mimeType,
                    "sizeBytes" to response.attachment.sizeBytes,
                    "httpStatus" to httpStatus
                )
            )
        )
    }

    fun logFailure(
        event: String,
        attachment: AmcAttachmentQueueEntity?,
        errorCode: String,
        message: String,
        throwable: Throwable? = null,
        extra: Map<String, Any?> = emptyMap()
    ) {
        val base = linkedMapOf<String, Any?>(
            "attachmentId" to attachment?.attachmentId,
            "draftRecordId" to attachment?.draftRecordId,
            "status" to attachment?.status,
            "attemptNumber" to attachment?.attemptNumber,
            "uploadSessionId" to attachment?.uploadSessionId,
            "retryCount" to attachment?.retryCount,
            "errorCode" to errorCode,
            "reason" to message
        ) + extra
        log(
            level = Log.ERROR,
            message = AmcAttachmentQueueLogFormatter.format(event = event, values = base),
            throwable = throwable
        )
    }

    private fun log(level: Int, message: String, throwable: Throwable? = null) {
        when (level) {
            Log.ERROR -> Log.e(TAG, message, throwable)
            Log.WARN -> Log.w(TAG, message, throwable)
            Log.INFO -> Log.i(TAG, message, throwable)
            else -> Log.d(TAG, message, throwable)
        }
    }
}

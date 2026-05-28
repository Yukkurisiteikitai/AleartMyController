package com.example.aleartmycontroller.data.amc

import com.example.aleartmycontroller.data.remote.amc.AmcAttachmentAttemptDescriptor
import com.example.aleartmycontroller.data.remote.amc.AmcAttachmentCompleteResponse
import com.example.aleartmycontroller.data.remote.amc.AmcAttachmentDescriptor
import com.example.aleartmycontroller.data.remote.amc.AmcAttachmentInitResponse
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class AmcAttachmentQueueLogFormatterTest {
    @Test
    fun format_includesRequiredKeysAndMasksSensitiveFields() {
        val message = AmcAttachmentQueueLogFormatter.format(
            event = "queue_enqueued",
            values = mapOf(
                "attachmentId" to 42,
                "draftRecordId" to 10,
                "status" to "PENDING",
                "localUri" to "file:///private/tmp/my photo.jpg",
                "uploadUrl" to "https://example.com/signed",
                "checksum" to "1234567890abcdef"
            )
        )

        assertTrue(message.contains("event=queue_enqueued"))
        assertTrue(message.contains("attachmentId=42"))
        assertTrue(message.contains("draftRecordId=10"))
        assertTrue(message.contains("localUri=my_photo.jpg"))
        assertTrue(message.contains("uploadUrl=[redacted]"))
        assertTrue(message.contains("checksum=12345678"))
        assertFalse(message.contains("https://example.com/signed"))
    }

    @Test
    fun format_replacesSpacesWithUnderscores() {
        val message = AmcAttachmentQueueLogFormatter.format(
            event = "api_complete_response",
            values = mapOf("reason" to "client upload failed")
        )

        assertTrue(message.contains("reason=client_upload_failed"))
    }

    @Test
    fun apiResponseFormatting_preservesResponseSummaryFields() {
        val initResponse = AmcAttachmentInitResponse(
            attachment = AmcAttachmentDescriptor(
                attachmentId = "att-1",
                r2Key = "r2/key",
                status = "uploading",
                mimeType = "image/jpeg",
                sizeBytes = 128,
                retryCount = 1,
                attemptNumber = 2,
                uploadSessionId = "session-1",
                expiresAtMillis = 1234L,
                lastErrorCode = "client_upload_failed",
                lastErrorReason = "upload failed"
            ),
            uploadSessionId = "session-1",
            attemptNumber = 2,
            uploadUrl = "https://example.com/upload",
            expiresAtMillis = 1234L,
            retryable = true
        )
        val completeResponse = AmcAttachmentCompleteResponse(
            attachment = initResponse.attachment,
            attempt = AmcAttachmentAttemptDescriptor(
                uploadSessionId = "session-1",
                attemptNumber = 2,
                status = "needs_retry",
                clientResult = AmcAttachmentClientResult.UPLOAD_FAILED,
                clientErrorCode = "timeout",
                serverErrorCode = "r2_object_missing",
                serverErrorReason = "missing",
                observedSizeBytes = 0L,
                observedContentType = "image/jpeg"
            ),
            verified = false,
            retryable = true,
            reason = "r2 object missing"
        )

        val initLog = AmcAttachmentQueueLogFormatter.format(
            event = "api_init_response",
            values = mapOf(
                "attemptNumber" to initResponse.attemptNumber,
                "uploadSessionId" to initResponse.uploadSessionId,
                "retryable" to initResponse.retryable,
                "expiresAtMillis" to initResponse.expiresAtMillis,
                "httpStatus" to 200
            )
        )
        val completeLog = AmcAttachmentQueueLogFormatter.format(
            event = "api_complete_response",
            values = mapOf(
                "verified" to completeResponse.verified,
                "retryable" to completeResponse.retryable,
                "clientResult" to completeResponse.attempt.clientResult,
                "errorCode" to completeResponse.attempt.serverErrorCode,
                "reason" to completeResponse.reason,
                "httpStatus" to 409
            )
        )

        assertTrue(initLog.contains("attemptNumber=2"))
        assertTrue(initLog.contains("uploadSessionId=session-1"))
        assertTrue(initLog.contains("retryable=true"))
        assertTrue(initLog.contains("expiresAtMillis=1234"))
        assertTrue(completeLog.contains("verified=false"))
        assertTrue(completeLog.contains("clientResult=UPLOAD_FAILED"))
        assertTrue(completeLog.contains("errorCode=r2_object_missing"))
        assertTrue(completeLog.contains("reason=r2_object_missing"))
        assertTrue(completeLog.contains("httpStatus=409"))
    }
}

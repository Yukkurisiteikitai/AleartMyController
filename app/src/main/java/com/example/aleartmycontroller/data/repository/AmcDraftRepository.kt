package com.example.aleartmycontroller.data.repository

import android.content.Context
import androidx.room.withTransaction
import android.util.Log
import androidx.work.BackoffPolicy
import androidx.work.Constraints
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import com.example.aleartmycontroller.data.amc.AmcAttachmentStatus
import com.example.aleartmycontroller.worker.AmcAttachmentUploadWorker
import dagger.hilt.android.qualifiers.ApplicationContext
import java.util.concurrent.TimeUnit
import com.example.aleartmycontroller.data.amc.AmcAttachmentType
import com.example.aleartmycontroller.data.amc.AmcContentPolicy
import com.example.aleartmycontroller.data.amc.AmcIdempotency
import com.example.aleartmycontroller.data.amc.AmcOutboxJobState
import com.example.aleartmycontroller.data.amc.AmcOutboxJobType
import com.example.aleartmycontroller.data.amc.AmcAttachmentQueueLogger
import com.example.aleartmycontroller.data.amc.AmcSource
import com.example.aleartmycontroller.data.amc.AmcSyncState
import com.example.aleartmycontroller.data.amc.AmcVisibility
import com.example.aleartmycontroller.data.local.AppDatabase
import com.example.aleartmycontroller.data.local.dao.AmcAttachmentQueueDao
import com.example.aleartmycontroller.data.local.dao.AmcDraftRecordDao
import com.example.aleartmycontroller.data.local.dao.AmcOutboxDao
import com.example.aleartmycontroller.data.local.dao.AmcRecordRevisionDao
import com.example.aleartmycontroller.data.local.entity.amc.AmcAttachmentQueueEntity
import com.example.aleartmycontroller.data.local.entity.amc.AmcDraftRecordEntity
import com.example.aleartmycontroller.data.local.entity.amc.AmcOutboxEntity
import com.example.aleartmycontroller.data.local.entity.amc.AmcRecordRevisionEntity
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject
import javax.inject.Singleton

class AmcConflictException(message: String) : IllegalStateException(message)

@Singleton
class AmcDraftRepository @Inject constructor(
    @ApplicationContext private val context: Context,
    private val db: AppDatabase,
    private val draftDao: AmcDraftRecordDao,
    private val revisionDao: AmcRecordRevisionDao,
    private val attachmentDao: AmcAttachmentQueueDao,
    private val outboxDao: AmcOutboxDao
) {
    fun observeDrafts(): Flow<List<AmcDraftRecordEntity>> = draftDao.observeAll()

    fun observePendingDraftCount(): Flow<Int> = draftDao.observePendingCount()

    fun observePendingAttachments(): Flow<List<AmcAttachmentQueueEntity>> = attachmentDao.observePendingUploads()

    fun observeOutbox(): Flow<List<AmcOutboxEntity>> = outboxDao.observePendingJobs()

    suspend fun createDraftRecord(
        eventId: Long?,
        ownerUserId: String?,
        visibility: AmcVisibility,
        initialBody: String = "",
        source: AmcSource = AmcSource.LOCAL_DRAFT,
        idempotencyKey: String = AmcIdempotency.newKey()
    ): Long = db.withTransaction {
        draftDao.findByIdempotencyKey(idempotencyKey)?.let { return@withTransaction it.draftRecordId }

        val now = System.currentTimeMillis()
        val body = AmcContentPolicy.normalizeBodyForStorage(initialBody)
        val draftId = draftDao.insert(
            AmcDraftRecordEntity(
                eventId = eventId,
                ownerUserId = ownerUserId,
                currentBody = body,
                visibility = visibility,
                currentRevision = 1,
                updatedAtMillis = now,
                createdAtMillis = now,
                source = source,
                syncState = AmcSyncState.DRAFT,
                idempotencyKey = idempotencyKey
            )
        )
        revisionDao.insert(
            AmcRecordRevisionEntity(
                draftRecordId = draftId,
                revisionNumber = 1,
                bodySnapshot = body,
                editorUserId = ownerUserId,
                createdAtMillis = now,
                idempotencyKey = "${idempotencyKey}:rev1"
            )
        )
        draftId
    }

    suspend fun appendRevision(
        draftRecordId: Long,
        newBody: String,
        editorUserId: String?,
        expectedRevision: Int? = null,
        changeSummary: String? = null,
        idempotencyKey: String = AmcIdempotency.newKey()
    ): Int = db.withTransaction {
        revisionDao.findByIdempotencyKey(idempotencyKey)?.let {
            return@withTransaction it.revisionNumber
        }

        val draft = draftDao.findById(draftRecordId)
            ?: error("Draft not found: $draftRecordId")
        if (draft.deletedAtMillis != null) {
            throw AmcConflictException("Draft already deleted: $draftRecordId")
        }
        if (expectedRevision != null && draft.currentRevision != expectedRevision) {
            throw AmcConflictException(
                "Revision conflict: expected=$expectedRevision actual=${draft.currentRevision}"
            )
        }

        val normalizedBody = AmcContentPolicy.normalizeBodyForStorage(newBody)
        if (normalizedBody == draft.currentBody) {
            return@withTransaction draft.currentRevision
        }

        val nextRevision = draft.currentRevision + 1
        val now = System.currentTimeMillis()

        revisionDao.insert(
            AmcRecordRevisionEntity(
                draftRecordId = draftRecordId,
                revisionNumber = nextRevision,
                bodySnapshot = normalizedBody,
                editorUserId = editorUserId,
                changeSummary = changeSummary,
                createdAtMillis = now,
                idempotencyKey = idempotencyKey
            )
        )
        draftDao.updateCurrentBody(
            draftRecordId = draftRecordId,
            currentBody = normalizedBody,
            currentRevision = nextRevision,
            updatedAtMillis = now,
            syncState = AmcSyncState.QUEUED.name
        )
        nextRevision
    }

    suspend fun markDraftDeleted(
        draftRecordId: Long,
        deletedByUserId: String?,
        idempotencyKey: String = AmcIdempotency.newKey()
    ) {
        db.withTransaction {
            val draft = draftDao.findById(draftRecordId)
                ?: error("Draft not found: $draftRecordId")
            if (draft.deletedAtMillis != null) return@withTransaction

            val now = System.currentTimeMillis()
            draftDao.markDeleted(
                draftRecordId = draftRecordId,
                deletedAtMillis = now,
                deletedByUserId = deletedByUserId,
                updatedAtMillis = now,
                syncState = AmcSyncState.QUEUED.name
            )
            insertOutboxJobInternal(
                jobType = AmcOutboxJobType.UPDATE_RECORD,
                payloadJson = """{"draftRecordId":$draftRecordId,"action":"delete"}""",
                idempotencyKey = idempotencyKey
            )
        }
    }

    suspend fun getOrCreateDraftForEvent(eventId: Long, ownerUserId: String?): Long =
        createDraftRecord(
            eventId = eventId,
            ownerUserId = ownerUserId,
            visibility = AmcVisibility.PRIVATE,
            idempotencyKey = "photo-draft:event:$eventId"
        )

    suspend fun queueAttachment(
        draftRecordId: Long,
        type: AmcAttachmentType,
        localUri: String,
        mimeType: String,
        sizeBytes: Long,
        checksum: String? = null,
        idempotencyKey: String = AmcIdempotency.newKey()
    ): Long = db.withTransaction {
        attachmentDao.findByIdempotencyKey(idempotencyKey)?.let { return@withTransaction it.attachmentId }

        require(AmcContentPolicy.isAllowedAttachmentMime(mimeType)) {
            "Unsupported MIME type: $mimeType"
        }

        val now = System.currentTimeMillis()
        val attachment = AmcAttachmentQueueEntity(
                draftRecordId = draftRecordId,
                type = type,
                localUri = localUri,
                mimeType = mimeType.lowercase(),
                sizeBytes = sizeBytes,
                checksum = checksum,
                status = AmcAttachmentStatus.PENDING,
                createdAtMillis = now,
                updatedAtMillis = now,
                idempotencyKey = idempotencyKey
            )
        val attachmentId = attachmentDao.insert(attachment)
        AmcAttachmentQueueLogger.logQueueEvent(
            level = Log.DEBUG,
            event = "queue_enqueued",
            attachment = attachment.copy(attachmentId = attachmentId),
            extra = mapOf("idempotencyKey" to idempotencyKey)
        )
        enqueueUploadWorker()
        attachmentId
    }

    private fun enqueueUploadWorker() {
        WorkManager.getInstance(context).enqueueUniqueWork(
            "amc_attachment_upload",
            ExistingWorkPolicy.KEEP,
            OneTimeWorkRequestBuilder<AmcAttachmentUploadWorker>()
                .setConstraints(Constraints(requiredNetworkType = NetworkType.CONNECTED))
                .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 30, TimeUnit.SECONDS)
                .build()
        )
    }

    suspend fun markAttachmentUploading(attachmentId: Long) {
        markAttachmentUploading(attachmentId = attachmentId, uploadSessionId = null, expiresAtMillis = null)
    }

    suspend fun markAttachmentUploading(
        attachmentId: Long,
        uploadSessionId: String?,
        expiresAtMillis: Long?
    ) {
        val now = System.currentTimeMillis()
        val current = attachmentDao.findById(attachmentId) ?: error("Attachment not found: $attachmentId")
        attachmentDao.updateStatus(
            attachmentId = attachmentId,
            status = AmcAttachmentStatus.UPLOADING.name,
            storagePath = current.storagePath,
            uploadSessionId = uploadSessionId,
            attemptNumber = current.attemptNumber + 1,
            lastErrorMessage = null,
            lastErrorCode = null,
            retryCount = current.retryCount,
            expiresAtMillis = expiresAtMillis,
            uploadedAtMillis = current.uploadedAtMillis,
            readyAtMillis = current.readyAtMillis,
            updatedAtMillis = now
        )
        AmcAttachmentQueueLogger.logQueueEvent(
            level = Log.DEBUG,
            event = "queue_uploading",
            attachment = current.copy(
                status = AmcAttachmentStatus.UPLOADING,
                uploadSessionId = uploadSessionId,
                attemptNumber = current.attemptNumber + 1,
                expiresAtMillis = expiresAtMillis,
                updatedAtMillis = now
            ),
            previousStatus = current.status
        )
    }

    suspend fun markAttachmentReady(
        attachmentId: Long,
        storagePath: String
    ) {
        val now = System.currentTimeMillis()
        val current = attachmentDao.findById(attachmentId) ?: error("Attachment not found: $attachmentId")
        attachmentDao.updateStatus(
            attachmentId = attachmentId,
            status = AmcAttachmentStatus.READY.name,
            storagePath = storagePath,
            uploadSessionId = current.uploadSessionId,
            attemptNumber = current.attemptNumber,
            lastErrorMessage = null,
            lastErrorCode = null,
            retryCount = current.retryCount,
            expiresAtMillis = current.expiresAtMillis,
            uploadedAtMillis = now,
            readyAtMillis = now,
            updatedAtMillis = now
        )
        AmcAttachmentQueueLogger.logQueueEvent(
            level = Log.INFO,
            event = "queue_ready",
            attachment = current.copy(
                status = AmcAttachmentStatus.READY,
                storagePath = storagePath,
                uploadedAtMillis = now,
                readyAtMillis = now,
                updatedAtMillis = now
            ),
            previousStatus = current.status
        )
    }

    suspend fun markAttachmentNeedsRetry(
        attachmentId: Long,
        errorCode: String,
        errorMessage: String
    ) {
        val now = System.currentTimeMillis()
        val current = attachmentDao.findById(attachmentId) ?: error("Attachment not found: $attachmentId")
        attachmentDao.updateStatus(
            attachmentId = attachmentId,
            status = AmcAttachmentStatus.NEEDS_RETRY.name,
            storagePath = current.storagePath,
            uploadSessionId = current.uploadSessionId,
            attemptNumber = current.attemptNumber,
            lastErrorMessage = errorMessage,
            lastErrorCode = errorCode,
            retryCount = current.retryCount + 1,
            expiresAtMillis = current.expiresAtMillis,
            uploadedAtMillis = current.uploadedAtMillis,
            readyAtMillis = current.readyAtMillis,
            updatedAtMillis = now
        )
        AmcAttachmentQueueLogger.logQueueEvent(
            level = Log.WARN,
            event = "queue_needs_retry",
            attachment = current.copy(
                status = AmcAttachmentStatus.NEEDS_RETRY,
                retryCount = current.retryCount + 1,
                lastErrorCode = errorCode,
                lastErrorMessage = errorMessage,
                updatedAtMillis = now
            ),
            previousStatus = current.status,
            extra = mapOf("retryable" to true, "reason" to errorMessage)
        )
    }

    suspend fun markAttachmentFailed(
        attachmentId: Long,
        errorCode: String,
        errorMessage: String
    ) {
        val now = System.currentTimeMillis()
        val current = attachmentDao.findById(attachmentId) ?: error("Attachment not found: $attachmentId")
        attachmentDao.updateStatus(
            attachmentId = attachmentId,
            status = AmcAttachmentStatus.FAILED.name,
            storagePath = current.storagePath,
            uploadSessionId = current.uploadSessionId,
            attemptNumber = current.attemptNumber,
            lastErrorMessage = errorMessage,
            lastErrorCode = errorCode,
            retryCount = current.retryCount + 1,
            expiresAtMillis = current.expiresAtMillis,
            uploadedAtMillis = current.uploadedAtMillis,
            readyAtMillis = current.readyAtMillis,
            updatedAtMillis = now
        )
        AmcAttachmentQueueLogger.logQueueEvent(
            level = Log.ERROR,
            event = "queue_failed",
            attachment = current.copy(
                status = AmcAttachmentStatus.FAILED,
                retryCount = current.retryCount + 1,
                lastErrorCode = errorCode,
                lastErrorMessage = errorMessage,
                updatedAtMillis = now
            ),
            previousStatus = current.status,
            extra = mapOf("retryable" to false, "reason" to errorMessage)
        )
    }

    suspend fun enqueueOutboxJob(
        jobType: AmcOutboxJobType,
        payloadJson: String,
        idempotencyKey: String = AmcIdempotency.newKey(),
        nextAttemptAtMillis: Long = System.currentTimeMillis()
    ): Long = db.withTransaction {
        insertOutboxJobInternal(jobType, payloadJson, idempotencyKey, nextAttemptAtMillis)
    }

    private suspend fun insertOutboxJobInternal(
        jobType: AmcOutboxJobType,
        payloadJson: String,
        idempotencyKey: String,
        nextAttemptAtMillis: Long = System.currentTimeMillis()
    ): Long {
        outboxDao.findByIdempotencyKey(idempotencyKey)?.jobId?.let { return it }

        val now = System.currentTimeMillis()
        return outboxDao.insert(
            AmcOutboxEntity(
                jobType = jobType,
                payloadJson = payloadJson,
                state = AmcOutboxJobState.PENDING,
                attemptCount = 0,
                nextAttemptAtMillis = nextAttemptAtMillis,
                createdAtMillis = now,
                updatedAtMillis = now,
                idempotencyKey = idempotencyKey
            )
        )
    }

    suspend fun normalizeAndBuildMirror(
        body: String,
        referenceUrl: String? = null
    ): String = AmcContentPolicy.buildCalendarMirrorBody(body, referenceUrl)
}

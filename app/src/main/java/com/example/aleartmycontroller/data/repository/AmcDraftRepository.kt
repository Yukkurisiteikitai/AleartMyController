package com.example.aleartmycontroller.data.repository

import androidx.room.withTransaction
import com.example.aleartmycontroller.data.amc.AmcAttachmentStatus
import com.example.aleartmycontroller.data.amc.AmcAttachmentType
import com.example.aleartmycontroller.data.amc.AmcContentPolicy
import com.example.aleartmycontroller.data.amc.AmcIdempotency
import com.example.aleartmycontroller.data.amc.AmcOutboxJobState
import com.example.aleartmycontroller.data.amc.AmcOutboxJobType
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
        attachmentDao.insert(
            AmcAttachmentQueueEntity(
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
        )
    }

    suspend fun markAttachmentUploading(attachmentId: Long) {
        val now = System.currentTimeMillis()
        val current = attachmentDao.findById(attachmentId) ?: error("Attachment not found: $attachmentId")
        attachmentDao.updateStatus(
            attachmentId = attachmentId,
            status = AmcAttachmentStatus.UPLOADING.name,
            r2Key = current.r2Key,
            lastErrorMessage = null,
            retryCount = current.retryCount,
            uploadedAtMillis = current.uploadedAtMillis,
            readyAtMillis = current.readyAtMillis,
            updatedAtMillis = now
        )
    }

    suspend fun markAttachmentReady(
        attachmentId: Long,
        r2Key: String
    ) {
        val now = System.currentTimeMillis()
        val current = attachmentDao.findById(attachmentId) ?: error("Attachment not found: $attachmentId")
        attachmentDao.updateStatus(
            attachmentId = attachmentId,
            status = AmcAttachmentStatus.READY.name,
            r2Key = r2Key,
            lastErrorMessage = null,
            retryCount = current.retryCount,
            uploadedAtMillis = now,
            readyAtMillis = now,
            updatedAtMillis = now
        )
    }

    suspend fun markAttachmentFailed(
        attachmentId: Long,
        errorMessage: String
    ) {
        val now = System.currentTimeMillis()
        val current = attachmentDao.findById(attachmentId) ?: error("Attachment not found: $attachmentId")
        attachmentDao.updateStatus(
            attachmentId = attachmentId,
            status = AmcAttachmentStatus.FAILED.name,
            r2Key = current.r2Key,
            lastErrorMessage = errorMessage,
            retryCount = current.retryCount + 1,
            uploadedAtMillis = current.uploadedAtMillis,
            readyAtMillis = current.readyAtMillis,
            updatedAtMillis = now
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

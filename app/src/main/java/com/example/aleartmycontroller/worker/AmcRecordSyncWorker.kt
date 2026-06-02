package com.example.aleartmycontroller.worker

import android.content.Context
import android.net.Uri
import android.util.Log
import androidx.hilt.work.HiltWorker
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.example.aleartmycontroller.data.local.dao.AmcAttachmentQueueDao
import com.example.aleartmycontroller.data.local.dao.AmcDraftRecordDao
import com.example.aleartmycontroller.data.local.dao.AmcRecordRevisionDao
import com.example.aleartmycontroller.data.local.entity.amc.AmcDraftRecordEntity
import com.example.aleartmycontroller.data.local.entity.amc.AmcRecordRevisionEntity
import com.example.aleartmycontroller.data.preferences.AppPreferences
import com.example.aleartmycontroller.data.repository.AmcDraftRepository
import com.example.aleartmycontroller.data.repository.AuthRepository
import dagger.assisted.Assisted
import dagger.assisted.AssistedInject
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.storage.storage
import kotlinx.coroutines.flow.first
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.put
import java.io.File

@HiltWorker
class AmcRecordSyncWorker @AssistedInject constructor(
    @Assisted appContext: Context,
    @Assisted workerParams: WorkerParameters,
    private val supabase: SupabaseClient,
    private val authRepository: AuthRepository,
    private val draftDao: AmcDraftRecordDao,
    private val revisionDao: AmcRecordRevisionDao,
    private val attachmentQueueDao: AmcAttachmentQueueDao,
    private val amcDraftRepository: AmcDraftRepository,
    private val appPreferences: AppPreferences
) : CoroutineWorker(appContext, workerParams) {

    override suspend fun doWork(): Result {
        if (!appPreferences.cloudSyncEnabled.first()) {
            Log.i(TAG, "Cloud sync disabled, skipping record sync")
            return Result.success()
        }
        if (!authRepository.isSupabaseAuthenticated()) {
            Log.w(TAG, "Supabase session not found, retrying later")
            return Result.retry()
        }

        val userId = authRepository.currentSupabaseUserId() ?: return Result.retry()
        val pendingDrafts = draftDao.getPendingSyncOnce()
        if (pendingDrafts.isEmpty()) return Result.success()

        var hasFailure = false
        for (draft in pendingDrafts) {
            runCatching {
                val remoteId = syncRecord(draft, userId)
                syncReadyAttachments(draft.draftRecordId, remoteId, userId)
                amcDraftRepository.markRecordSynced(draft.draftRecordId, remoteId)
                Log.i(TAG, "Synced record: local=${draft.draftRecordId} remote=$remoteId")
            }.onFailure {
                hasFailure = true
                Log.e(TAG, "Sync failed for draft ${draft.draftRecordId}", it)
            }
        }

        return if (hasFailure) Result.retry() else Result.success()
    }

    private suspend fun syncRecord(draft: AmcDraftRecordEntity, userId: String): String {
        val remoteId = if (draft.remoteRecordId == null) {
            val response = supabase.from("amc_records").insert(
                buildJsonObject {
                    put("owner_user_id", userId)
                    put("current_body", draft.currentBody)
                    put("visibility", draft.visibility.name)
                }
            ) { select() }
            response.decodeSingle<JsonObject>()["id"]!!.jsonPrimitive.content
        } else {
            supabase.from("amc_records").update(
                buildJsonObject {
                    put("current_body", draft.currentBody)
                    put("visibility", draft.visibility.name)
                }
            ) { filter { eq("id", draft.remoteRecordId) } }
            draft.remoteRecordId
        }

        val revision = revisionDao.findLatestForDraft(draft.draftRecordId) ?: return remoteId
        upsertRevision(revision, remoteId, userId)
        return remoteId
    }

    private suspend fun upsertRevision(
        revision: AmcRecordRevisionEntity,
        remoteRecordId: String,
        userId: String
    ) {
        val response = supabase.from("amc_record_revisions").upsert(
            buildJsonObject {
                put("record_id", remoteRecordId)
                put("editor_user_id", userId)
                put("body", revision.bodySnapshot)
                put("idempotency_key", revision.idempotencyKey)
            }
        ) {
            onConflict = "idempotency_key"
            ignoreDuplicates = true
            select()
        }

        val revisionId = response.decodeSingleOrNull<JsonObject>()
            ?.get("id")?.jsonPrimitive?.content ?: return

        supabase.from("amc_records").update(
            buildJsonObject { put("current_revision", revisionId) }
        ) { filter { eq("id", remoteRecordId) } }
    }

    private suspend fun syncReadyAttachments(
        draftRecordId: Long,
        remoteRecordId: String,
        userId: String
    ) {
        val readyAttachments = attachmentQueueDao.getReadyByDraftId(draftRecordId)
        for (att in readyAttachments) {
            runCatching {
                supabase.from("amc_attachments").insert(
                    buildJsonObject {
                        put("record_id", remoteRecordId)
                        put("uploader_user_id", userId)
                        put("type", att.type.name)
                        put("mime_type", att.mimeType)
                        put("storage_path", att.storagePath!!)
                        put("file_size_bytes", att.sizeBytes)
                        att.checksum?.let { put("checksum", it) }
                        put("status", "READY")
                    }
                )
                resolveLocalFile(att.localUri)?.delete()
                Log.i(TAG, "Attachment registered and local file deleted: ${att.attachmentId}")
            }.onFailure {
                Log.e(TAG, "Failed to register attachment ${att.attachmentId}", it)
            }
        }
    }

    private fun resolveLocalFile(localUri: String): File? {
        val path = Uri.parse(localUri).path ?: return null
        val file = File(path)
        return if (file.exists()) file else null
    }

    companion object {
        private const val TAG = "AMC.RecordSyncWorker"
    }
}

package com.example.aleartmycontroller.worker

import android.content.Context
import android.net.Uri
import android.util.Log
import androidx.hilt.work.HiltWorker
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.example.aleartmycontroller.data.amc.AmcAttachmentType
import com.example.aleartmycontroller.data.local.dao.AmcAttachmentQueueDao
import com.example.aleartmycontroller.data.repository.AmcDraftRepository
import com.example.aleartmycontroller.data.repository.AuthRepository
import dagger.assisted.Assisted
import dagger.assisted.AssistedInject
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.storage.storage
import java.io.File

@HiltWorker
class AmcAttachmentUploadWorker @AssistedInject constructor(
    @Assisted appContext: Context,
    @Assisted workerParams: WorkerParameters,
    private val supabase: SupabaseClient,
    private val authRepository: AuthRepository,
    private val amcDraftRepository: AmcDraftRepository,
    private val attachmentQueueDao: AmcAttachmentQueueDao
) : CoroutineWorker(appContext, workerParams) {

    override suspend fun doWork(): Result {
        if (!authRepository.isSupabaseAuthenticated()) {
            Log.w(TAG, "Supabase session not found, retrying later")
            return Result.retry()
        }

        val userId = authRepository.currentSupabaseUserId() ?: return Result.retry()
        val pending = attachmentQueueDao.getPendingOnce()

        if (pending.isEmpty()) return Result.success()

        var hasFailure = false
        for (attachment in pending) {
            val file = resolveLocalFile(attachment.localUri)
            if (file == null) {
                amcDraftRepository.markAttachmentFailed(
                    attachment.attachmentId, "FILE_NOT_FOUND", "Local file missing: ${attachment.localUri}"
                )
                hasFailure = true
            } else {
                amcDraftRepository.markAttachmentUploading(attachment.attachmentId)

                val ext = if (attachment.type == AmcAttachmentType.IMAGE) "jpg" else "m4a"
                val storagePath = "$userId/${attachment.draftRecordId}/${attachment.attachmentId}.$ext"

                runCatching {
                    supabase.storage.from("amc-media").upload(storagePath, file.readBytes())
                }.onSuccess {
                    amcDraftRepository.markAttachmentReady(attachment.attachmentId, storagePath)
                    file.delete()
                    Log.i(TAG, "Uploaded: $storagePath")
                }.onFailure { e ->
                    hasFailure = true
                    val msg = e.message ?: "Upload failed"
                    if (runAttemptCount < MAX_ATTEMPTS) {
                        amcDraftRepository.markAttachmentNeedsRetry(attachment.attachmentId, "UPLOAD_FAILED", msg)
                    } else {
                        amcDraftRepository.markAttachmentFailed(attachment.attachmentId, "UPLOAD_FAILED", msg)
                    }
                    Log.e(TAG, "Upload failed for ${attachment.attachmentId}: $msg", e)
                }
            }
        }

        return if (hasFailure) Result.retry() else Result.success()
    }

    private fun resolveLocalFile(localUri: String): File? {
        val uri = Uri.parse(localUri)
        val path = uri.path ?: return null
        val file = File(path)
        return if (file.exists()) file else null
    }

    companion object {
        private const val TAG = "AMC.UploadWorker"
        private const val MAX_ATTEMPTS = 3
    }
}

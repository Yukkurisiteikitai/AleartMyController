package com.example.aleartmycontroller.data.repository

import android.content.ContentValues
import android.content.Context
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.util.Log
import dagger.hilt.android.qualifiers.ApplicationContext
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.storage.storage
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AmcStorageRepository @Inject constructor(
    @ApplicationContext private val context: Context,
    private val supabase: SupabaseClient
) {
    /**
     * Supabase Storage から添付ファイルをダウンロードし、デバイスの Downloads フォルダに保存する。
     * 返り値は保存先の MediaStore URI。
     */
    suspend fun downloadToLocal(attachmentId: Long, storagePath: String, mimeType: String): Uri {
        val bytes = supabase.storage.from("amc-media").downloadAuthenticated(storagePath)

        val ext = when {
            mimeType.contains("jpeg") || mimeType.contains("jpg") -> "jpg"
            mimeType.contains("png") -> "png"
            mimeType.contains("m4a") || mimeType.contains("mp4a") -> "m4a"
            else -> "bin"
        }
        val filename = "amc_${attachmentId}.$ext"

        val resolver = context.contentResolver
        val collection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        } else {
            MediaStore.Files.getContentUri("external")
        }

        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, filename)
            put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
        }

        val uri = resolver.insert(collection, values)
            ?: error("Failed to create MediaStore entry for $filename")

        resolver.openOutputStream(uri)!!.use { it.write(bytes) }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            values.clear()
            values.put(MediaStore.MediaColumns.IS_PENDING, 0)
            resolver.update(uri, values, null as String?, null)
        }

        Log.i(TAG, "Downloaded attachment $attachmentId to $uri")
        return uri
    }

    companion object {
        private const val TAG = "AMC.StorageRepository"
    }
}

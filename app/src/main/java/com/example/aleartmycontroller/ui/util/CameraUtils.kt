package com.example.aleartmycontroller.ui.util

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Environment
import androidx.core.content.FileProvider
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

object CameraUtils {
    /**
     * カメラ撮影用の一時的な画像ファイルを作成し、その Content URI を返す。
     * ファイルはアプリ専用保存領域の Pictures ディレクトリに保存される。
     */
    fun createImageUri(context: Context): Uri {
        val timeStamp: String = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
        val storageDir: File? = context.getExternalFilesDir(Environment.DIRECTORY_PICTURES)
        val imageFile = File.createTempFile(
            "JPEG_${timeStamp}_",
            ".jpg",
            storageDir
        )
        return FileProvider.getUriForFile(
            context,
            "${context.packageName}.fileprovider",
            imageFile
        )
    }

    /**
     * content:// または file:// URI の画像を JPEG に圧縮して返す。
     * 出力先は cacheDir/amc_upload/。アップロード完了後に呼び出し元が削除すること。
     */
    fun compressToJpeg(context: Context, sourceUri: Uri, quality: Int = 85): File {
        val opts = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        context.contentResolver.openInputStream(sourceUri)?.use { BitmapFactory.decodeStream(it, null, opts) }

        val maxDim = 2048
        opts.inSampleSize = calculateInSampleSize(opts.outWidth, opts.outHeight, maxDim)
        opts.inJustDecodeBounds = false

        val bitmap = context.contentResolver.openInputStream(sourceUri)?.use {
            BitmapFactory.decodeStream(it, null, opts)
        } ?: error("Failed to decode image: $sourceUri")

        val uploadDir = File(context.cacheDir, "amc_upload").also { it.mkdirs() }
        val outFile = File(uploadDir, "img_${System.currentTimeMillis()}.jpg")
        outFile.outputStream().use { bitmap.compress(Bitmap.CompressFormat.JPEG, quality, it) }
        bitmap.recycle()
        return outFile
    }

    private fun calculateInSampleSize(width: Int, height: Int, maxDim: Int): Int {
        var sampleSize = 1
        val larger = maxOf(width, height)
        while (larger / sampleSize > maxDim) sampleSize *= 2
        return sampleSize
    }
}

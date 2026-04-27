package com.example.aleartmycontroller.ui.util

import android.content.Context
import android.media.MediaRecorder
import android.net.Uri
import android.os.Build
import android.os.Environment
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

object AudioUtils {

    fun createAudioFile(context: Context): File {
        val timeStamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
        val storageDir = context.getExternalFilesDir(Environment.DIRECTORY_PODCASTS)
        return File(storageDir, "AUDIO_${timeStamp}_.m4a")
    }

    fun createRecorder(context: Context): MediaRecorder =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            MediaRecorder(context)
        } else {
            @Suppress("DEPRECATION")
            MediaRecorder()
        }

    fun startRecording(recorder: MediaRecorder, filePath: String) {
        recorder.apply {
            setAudioSource(MediaRecorder.AudioSource.MIC)
            setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
            setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
            setOutputFile(filePath)
            prepare()
            start()
        }
    }

    fun stopRecording(recorder: MediaRecorder) {
        recorder.stop()
        recorder.release()
    }

    /** 外部から選択した音声 URI をアプリ内ストレージにコピーして File を返す */
    fun copyToAppStorage(context: Context, uri: Uri): File {
        val timeStamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
        val storageDir = context.getExternalFilesDir(Environment.DIRECTORY_PODCASTS)
        val dest = File(storageDir, "AUDIO_${timeStamp}_.m4a")
        context.contentResolver.openInputStream(uri)?.use { input ->
            dest.outputStream().use { output -> input.copyTo(output) }
        }
        return dest
    }
}

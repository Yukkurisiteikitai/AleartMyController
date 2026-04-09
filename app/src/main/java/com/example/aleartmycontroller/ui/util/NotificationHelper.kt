package com.example.aleartmycontroller.ui.util

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.example.aleartmycontroller.MainActivity
import com.example.aleartmycontroller.R

object NotificationHelper {
    private const val CHANNEL_ID = "observation_reminders"
    private const val CHANNEL_NAME = "観察リマインダー"

    fun createNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(CHANNEL_ID, CHANNEL_NAME, importance).apply {
                description = "撮影やメモの記録を促す通知です。"
            }
            val notificationManager: NotificationManager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    fun showReminderNotification(context: Context, eventId: Long, title: String, content: String) {
        // MainActivity を開くインテント
        // eventId を渡して特定の画面へ遷移させる仕組みが必要
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            putExtra("eventId", eventId)
        }
        
        val pendingIntent: PendingIntent = PendingIntent.getActivity(
            context, 
            eventId.toInt(), 
            intent, 
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info) // 本来は専用アイコン
            .setContentTitle(title)
            .setContentText(content)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)

        with(NotificationManagerCompat.from(context)) {
            // Android 13+ では通知権限が必要だが、ここでは簡易化のため通知発行のみ
            notify(eventId.toInt(), builder.build())
        }
    }
}

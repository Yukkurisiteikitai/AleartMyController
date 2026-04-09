package com.example.aleartmycontroller.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

import androidx.room.Index

/**
 * Google Calendar イベントのローカルキャッシュ。
 * google_event_id はCalendar APIから取得したイベントの一意ID。
 */
@Entity(
    tableName = "events",
    indices = [Index(value = ["googleEventId"], unique = true)]
)
data class EventEntity(
    @PrimaryKey(autoGenerate = true) val eventId: Long = 0,
    val googleEventId: String,
    val title: String,
    val startTime: Long,   // epoch millis
    val endTime: Long      // epoch millis
)

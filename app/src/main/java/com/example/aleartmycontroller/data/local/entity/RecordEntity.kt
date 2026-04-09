package com.example.aleartmycontroller.data.local.entity

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey

/** 記録タイプ。photo / memo の2種類 */
enum class RecordType { PHOTO, MEMO }

/**
 * イベントに紐づく観察ログ1件。
 * event_id は EventEntity の外部キー。
 */
@Entity(
    tableName = "records",
    foreignKeys = [
        ForeignKey(
            entity = EventEntity::class,
            parentColumns = ["eventId"],
            childColumns = ["eventId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [Index("eventId")]
)
data class RecordEntity(
    @PrimaryKey(autoGenerate = true) val recordId: Long = 0,
    val eventId: Long,
    val recordTime: Long,          // epoch millis
    val recordType: RecordType
)

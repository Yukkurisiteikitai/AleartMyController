package com.example.aleartmycontroller.data.local.entity

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey

/** 記録タイプ。photo / memo の2種類 */
enum class RecordType { PHOTO, MEMO }

/**
 * イベントに紐づく観察ログ1件。
 * obsEventId は ObservationEventEntity の外部キー。
 * EventEntity（Google Calendar キャッシュ）には依存しない。
 */
@Entity(
    tableName = "records",
    foreignKeys = [
        ForeignKey(
            entity = ObservationEventEntity::class,
            parentColumns = ["obsEventId"],
            childColumns = ["obsEventId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [Index("obsEventId")]
)
data class RecordEntity(
    @PrimaryKey(autoGenerate = true) val recordId: Long = 0,
    val obsEventId: Long,
    val recordTime: Long,          // epoch millis
    val recordType: RecordType
)

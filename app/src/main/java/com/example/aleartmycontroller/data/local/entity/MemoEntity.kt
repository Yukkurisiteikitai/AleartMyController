package com.example.aleartmycontroller.data.local.entity

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey

/**
 * テキスト・音声メモ記録。
 * record_id は RecordEntity の外部キー。
 * memo_text はテキスト入力または Speech-to-Text の結果。
 */
@Entity(
    tableName = "memos",
    foreignKeys = [
        ForeignKey(
            entity = RecordEntity::class,
            parentColumns = ["recordId"],
            childColumns = ["recordId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [Index("recordId")]
)
data class MemoEntity(
    @PrimaryKey(autoGenerate = true) val memoId: Long = 0,
    val recordId: Long,
    val memoText: String,
    val isVoiceMemo: Boolean = false,
    val audioFilePath: String? = null
)

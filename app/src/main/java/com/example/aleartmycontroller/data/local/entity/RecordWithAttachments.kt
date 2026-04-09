package com.example.aleartmycontroller.data.local.entity

import androidx.room.Embedded
import androidx.room.Relation

/**
 * 記録本体とその添付ファイル（写真・メモ）をまとめたPOJO。
 * N+1問題を避けるために使用する。
 */
data class RecordWithAttachments(
    @Embedded val record: RecordEntity,

    @Relation(
        parentColumn = "recordId",
        entityColumn = "recordId"
    )
    val photos: List<PhotoEntity>,

    @Relation(
        parentColumn = "recordId",
        entityColumn = "recordId"
    )
    val memos: List<MemoEntity>
)

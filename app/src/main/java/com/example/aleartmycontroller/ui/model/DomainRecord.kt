package com.example.aleartmycontroller.ui.model

import com.example.aleartmycontroller.data.local.entity.RecordType
import com.example.aleartmycontroller.data.local.entity.RecordWithAttachments

/**
 * UI層・ビジネスロジック層で扱うための型安全なドメインモデル。
 * RoomのEntity構造（DBスキーマ）を隠蔽し、安全にデータをUIへ提供する。
 */
sealed class DomainRecord {
    abstract val id: Long
    abstract val time: Long

    /** 写真記録: 複数の写真パスを保持可能 */
    data class PhotoRecord(
        override val id: Long,
        override val time: Long,
        val photoPaths: List<String>
    ) : DomainRecord()

    /** メモ記録: 複数のテキストを保持可能 */
    data class MemoRecord(
        override val id: Long,
        override val time: Long,
        val texts: List<String>
    ) : DomainRecord()
}

/**
 * DBのデータ (RecordWithAttachments) をドメインモデル (DomainRecord) に変換する
 */
fun RecordWithAttachments.toDomainModel(): DomainRecord {
    return when (record.recordType) {
        RecordType.PHOTO -> DomainRecord.PhotoRecord(
            id = record.recordId,
            time = record.recordTime,
            photoPaths = photos.map { it.filePath }
        )
        RecordType.MEMO -> DomainRecord.MemoRecord(
            id = record.recordId,
            time = record.recordTime,
            texts = memos.map { it.memoText }
        )
    }
}

package com.example.aleartmycontroller.data.local.entity

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey

/**
 * 写真記録。record_id は RecordEntity の外部キー。
 * file_path は端末ストレージ上の絶対パス。
 */
@Entity(
    tableName = "photos",
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
data class PhotoEntity(
    @PrimaryKey(autoGenerate = true) val photoId: Long = 0,
    val recordId: Long,
    val filePath: String
)

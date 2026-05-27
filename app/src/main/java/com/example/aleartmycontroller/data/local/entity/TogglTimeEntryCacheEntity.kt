package com.example.aleartmycontroller.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "toggl_time_entry_cache")
data class TogglTimeEntryCacheEntity(
    @PrimaryKey val remoteId: Long,
    val workspaceId: Long,
    val description: String?,
    val startMillis: Long,
    val durationSeconds: Long,
    val tagsCsv: String = "",
    val syncedAtMillis: Long = System.currentTimeMillis()
)

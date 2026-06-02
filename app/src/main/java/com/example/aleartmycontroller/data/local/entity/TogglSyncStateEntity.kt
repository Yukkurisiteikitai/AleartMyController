package com.example.aleartmycontroller.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "toggl_sync_state")
data class TogglSyncStateEntity(
    @PrimaryKey val id: Int = SINGLETON_ID,
    val autoSyncEnabled: Boolean = false,
    val syncStatus: String = "UNCONFIGURED",
    val lastSyncedAtMillis: Long? = null,
    val lastAttemptAtMillis: Long? = null,
    val lastErrorMessage: String? = null,
    val defaultWorkspaceId: Long? = null
) {
    companion object {
        const val SINGLETON_ID: Int = 0
    }
}

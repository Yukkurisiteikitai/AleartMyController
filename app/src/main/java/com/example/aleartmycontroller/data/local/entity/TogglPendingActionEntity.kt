package com.example.aleartmycontroller.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "toggl_pending_actions")
data class TogglPendingActionEntity(
    @PrimaryKey(autoGenerate = true) val actionId: Long = 0,
    val actionType: String,
    val description: String? = null,
    val tagsCsv: String = "",
    val createdAtMillis: Long = System.currentTimeMillis(),
    val attemptCount: Int = 0,
    val lastAttemptAtMillis: Long? = null,
    val lastErrorMessage: String? = null
) {
    companion object {
        const val ACTION_CREATE = "CREATE_ENTRY"
        const val ACTION_STOP = "STOP_CURRENT_ENTRY"
    }
}

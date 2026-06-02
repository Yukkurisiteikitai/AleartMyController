package com.example.aleartmycontroller.data.local.entity.amc

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey
import com.example.aleartmycontroller.data.amc.AmcOutboxJobState
import com.example.aleartmycontroller.data.amc.AmcOutboxJobType

@Entity(
    tableName = "amc_outbox_jobs",
    indices = [
        Index("jobType"),
        Index("state"),
        Index(value = ["idempotencyKey"], unique = true)
    ]
)
data class AmcOutboxEntity(
    @PrimaryKey(autoGenerate = true) val jobId: Long = 0,
    val jobType: AmcOutboxJobType,
    val payloadJson: String,
    val state: AmcOutboxJobState = AmcOutboxJobState.PENDING,
    val attemptCount: Int = 0,
    val nextAttemptAtMillis: Long = 0,
    val lastErrorMessage: String? = null,
    val createdAtMillis: Long,
    val updatedAtMillis: Long,
    val idempotencyKey: String
)


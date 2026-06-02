package com.example.aleartmycontroller.data.local.entity.amc

import androidx.room.TypeConverter
import com.example.aleartmycontroller.data.amc.AmcAttachmentStatus
import com.example.aleartmycontroller.data.amc.AmcAttachmentType
import com.example.aleartmycontroller.data.amc.AmcOutboxJobState
import com.example.aleartmycontroller.data.amc.AmcOutboxJobType
import com.example.aleartmycontroller.data.amc.AmcSource
import com.example.aleartmycontroller.data.amc.AmcSyncState
import com.example.aleartmycontroller.data.amc.AmcVisibility

class AmcTypeConverters {
    @TypeConverter
    fun fromVisibility(value: AmcVisibility): String = value.name

    @TypeConverter
    fun toVisibility(value: String): AmcVisibility = AmcVisibility.valueOf(value)

    @TypeConverter
    fun fromAttachmentType(value: AmcAttachmentType): String = value.name

    @TypeConverter
    fun toAttachmentType(value: String): AmcAttachmentType = AmcAttachmentType.valueOf(value)

    @TypeConverter
    fun fromAttachmentStatus(value: AmcAttachmentStatus): String = value.name

    @TypeConverter
    fun toAttachmentStatus(value: String): AmcAttachmentStatus = AmcAttachmentStatus.valueOf(value)

    @TypeConverter
    fun fromSyncState(value: AmcSyncState): String = value.name

    @TypeConverter
    fun toSyncState(value: String): AmcSyncState = AmcSyncState.valueOf(value)

    @TypeConverter
    fun fromSource(value: AmcSource): String = value.name

    @TypeConverter
    fun toSource(value: String): AmcSource = AmcSource.valueOf(value)

    @TypeConverter
    fun fromOutboxJobType(value: AmcOutboxJobType): String = value.name

    @TypeConverter
    fun toOutboxJobType(value: String): AmcOutboxJobType = AmcOutboxJobType.valueOf(value)

    @TypeConverter
    fun fromOutboxJobState(value: AmcOutboxJobState): String = value.name

    @TypeConverter
    fun toOutboxJobState(value: String): AmcOutboxJobState = AmcOutboxJobState.valueOf(value)
}


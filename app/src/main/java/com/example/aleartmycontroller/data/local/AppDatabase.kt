package com.example.aleartmycontroller.data.local

import androidx.room.Database
import androidx.room.RoomDatabase
import androidx.room.TypeConverter
import androidx.room.TypeConverters
import com.example.aleartmycontroller.data.local.dao.EventDao
import com.example.aleartmycontroller.data.local.dao.MemoDao
import com.example.aleartmycontroller.data.local.dao.PhotoDao
import com.example.aleartmycontroller.data.local.dao.RecordDao
import com.example.aleartmycontroller.data.local.entity.EventEntity
import com.example.aleartmycontroller.data.local.entity.MemoEntity
import com.example.aleartmycontroller.data.local.entity.PhotoEntity
import com.example.aleartmycontroller.data.local.entity.RecordEntity
import com.example.aleartmycontroller.data.local.entity.RecordType

// ---- TypeConverters ----

class RecordTypeConverter {
    @TypeConverter
    fun fromRecordType(value: RecordType): String = value.name

    @TypeConverter
    fun toRecordType(value: String): RecordType = RecordType.valueOf(value)
}

// ---- Database ----

@Database(
    entities = [EventEntity::class, RecordEntity::class, PhotoEntity::class, MemoEntity::class],
    version = 1,
    exportSchema = false
)
@TypeConverters(RecordTypeConverter::class)
abstract class AppDatabase : RoomDatabase() {
    abstract fun eventDao(): EventDao
    abstract fun recordDao(): RecordDao
    abstract fun photoDao(): PhotoDao
    abstract fun memoDao(): MemoDao

    companion object {
        const val DATABASE_NAME = "aleart_my_controller.db"
    }
}

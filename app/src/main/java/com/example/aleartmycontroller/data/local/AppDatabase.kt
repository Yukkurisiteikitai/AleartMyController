package com.example.aleartmycontroller.data.local

import androidx.room.Database
import androidx.room.RoomDatabase
import androidx.room.TypeConverter
import androidx.room.TypeConverters
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase
import com.example.aleartmycontroller.data.local.dao.AnalyticsDao
import com.example.aleartmycontroller.data.local.dao.EventDao
import com.example.aleartmycontroller.data.local.dao.MemoDao
import com.example.aleartmycontroller.data.local.dao.PhotoDao
import com.example.aleartmycontroller.data.local.dao.RecordDao
import com.example.aleartmycontroller.data.local.entity.EventEntity
import com.example.aleartmycontroller.data.local.entity.MemoEntity
import com.example.aleartmycontroller.data.local.entity.ObservationEventEntity
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
    entities = [EventEntity::class, RecordEntity::class, PhotoEntity::class, MemoEntity::class,
                ObservationEventEntity::class],
    version = 3,
    exportSchema = true
)
@TypeConverters(RecordTypeConverter::class)
abstract class AppDatabase : RoomDatabase() {
    abstract fun analyticsDao(): AnalyticsDao
    abstract fun eventDao(): EventDao
    abstract fun recordDao(): RecordDao
    abstract fun photoDao(): PhotoDao
    abstract fun memoDao(): MemoDao

    companion object {
        const val DATABASE_NAME = "aleart_my_controller.db"

        val MIGRATION_1_2 = object : Migration(1, 2) {
            override fun migrate(db: SupportSQLiteDatabase) {
                // googleEventId にユニークインデックスを追加
                db.execSQL("CREATE UNIQUE INDEX IF NOT EXISTS index_events_googleEventId ON events(googleEventId)")
            }
        }

        /**
         * v2 → v3: observation_events テーブルの新設と既存データの昇格。
         *
         * 目的: EventEntity（Googleカレンダーキャッシュ）のライフサイクルから
         *       ユーザー記録を切り離す。
         *
         * 処理:
         *   1. observation_events テーブルを作成する。
         *   2. records を持つ events を observation_events へコピーする。
         *      records を持たない events（未観察のカレンダーイベント）はコピーしない。
         *
         * 注意: この migration では records.eventId の FK 先は変更しない。
         *       FK 先の付け替え（records.obsEventId 追加）は次の migration で行う。
         */
        val MIGRATION_2_3 = object : Migration(2, 3) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL(
                    """
                    CREATE TABLE IF NOT EXISTS `observation_events` (
                        `obsEventId`    INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                        `googleEventId` TEXT,
                        `title`         TEXT NOT NULL,
                        `startTime`     INTEGER NOT NULL,
                        `endTime`       INTEGER NOT NULL
                    )
                    """.trimIndent()
                )
                db.execSQL(
                    """
                    INSERT INTO observation_events (googleEventId, title, startTime, endTime)
                    SELECT e.googleEventId, e.title, e.startTime, e.endTime
                    FROM events e
                    WHERE e.eventId IN (SELECT DISTINCT eventId FROM records)
                    """.trimIndent()
                )
            }
        }
    }
}

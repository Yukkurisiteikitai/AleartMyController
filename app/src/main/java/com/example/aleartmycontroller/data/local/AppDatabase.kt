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
import com.example.aleartmycontroller.data.local.dao.ObservationEventDao
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
    version = 4,
    exportSchema = true
)
@TypeConverters(RecordTypeConverter::class)
abstract class AppDatabase : RoomDatabase() {
    abstract fun analyticsDao(): AnalyticsDao
    abstract fun eventDao(): EventDao
    abstract fun observationEventDao(): ObservationEventDao
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
         * records を持つ events のみ昇格する。records.eventId FK は次の migration で切り替える。
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

        /**
         * v3 → v4: records テーブルの FK を events → observation_events へ切り替え。
         *
         * SQLite は ALTER TABLE DROP COLUMN / MODIFY COLUMN をサポートしないため、
         * create-copy-drop-rename パターンで置き換える。
         *
         * 処理:
         *   1. observation_events.googleEventId にユニークインデックスを追加
         *   2. Migration 2→3 以降に追加された records のイベントを catch-up 昇格
         *   3. obsEventId FK を持つ新テーブル records_new を作成
         *   4. events → observation_events JOIN で eventId を obsEventId に解決しながらコピー
         *   5. 旧テーブルを削除 → リネーム → インデックス再作成
         */
        val MIGRATION_3_4 = object : Migration(3, 4) {
            override fun migrate(db: SupportSQLiteDatabase) {
                // 1. ユニークインデックス（INSERT OR IGNORE のために必要）
                db.execSQL(
                    "CREATE UNIQUE INDEX IF NOT EXISTS `index_observation_events_googleEventId` " +
                    "ON `observation_events`(`googleEventId`)"
                )
                // 2. catch-up: 2→3 移行後に新規観察されたイベントを昇格
                db.execSQL(
                    """
                    INSERT OR IGNORE INTO observation_events (googleEventId, title, startTime, endTime)
                    SELECT e.googleEventId, e.title, e.startTime, e.endTime
                    FROM events e
                    WHERE e.eventId IN (SELECT DISTINCT eventId FROM records)
                    """.trimIndent()
                )
                // 3. 新スキーマの records_new
                db.execSQL(
                    """
                    CREATE TABLE `records_new` (
                        `recordId`   INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                        `obsEventId` INTEGER NOT NULL,
                        `recordTime` INTEGER NOT NULL,
                        `recordType` TEXT NOT NULL,
                        FOREIGN KEY(`obsEventId`) REFERENCES `observation_events`(`obsEventId`)
                            ON UPDATE NO ACTION ON DELETE CASCADE
                    )
                    """.trimIndent()
                )
                // 4. eventId → obsEventId に変換しながらコピー
                db.execSQL(
                    """
                    INSERT INTO records_new (recordId, obsEventId, recordTime, recordType)
                    SELECT r.recordId, oe.obsEventId, r.recordTime, r.recordType
                    FROM records r
                    INNER JOIN events e  ON e.eventId        = r.eventId
                    INNER JOIN observation_events oe ON oe.googleEventId = e.googleEventId
                    """.trimIndent()
                )
                // 5. 置き換え
                db.execSQL("DROP TABLE `records`")
                db.execSQL("ALTER TABLE `records_new` RENAME TO `records`")
                db.execSQL(
                    "CREATE INDEX IF NOT EXISTS `index_records_obsEventId` ON `records`(`obsEventId`)"
                )
            }
        }
    }
}

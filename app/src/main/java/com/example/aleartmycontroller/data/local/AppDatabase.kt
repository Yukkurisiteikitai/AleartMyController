package com.example.aleartmycontroller.data.local

import androidx.room.Database
import androidx.room.RoomDatabase
import androidx.room.TypeConverter
import androidx.room.TypeConverters
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase
import com.example.aleartmycontroller.data.local.dao.AnalyticsDao
import com.example.aleartmycontroller.data.local.dao.AmcAttachmentQueueDao
import com.example.aleartmycontroller.data.local.dao.AmcDraftRecordDao
import com.example.aleartmycontroller.data.local.dao.AmcOutboxDao
import com.example.aleartmycontroller.data.local.dao.AmcRecordRevisionDao
import com.example.aleartmycontroller.data.local.dao.EventDao
import com.example.aleartmycontroller.data.local.dao.MemoDao
import com.example.aleartmycontroller.data.local.dao.ObservationEventDao
import com.example.aleartmycontroller.data.local.dao.PhotoDao
import com.example.aleartmycontroller.data.local.dao.RecordDao
import com.example.aleartmycontroller.data.local.dao.TogglPendingActionDao
import com.example.aleartmycontroller.data.local.dao.TogglSyncStateDao
import com.example.aleartmycontroller.data.local.dao.TogglTimeEntryCacheDao
import com.example.aleartmycontroller.data.local.entity.EventEntity
import com.example.aleartmycontroller.data.local.entity.MemoEntity
import com.example.aleartmycontroller.data.local.entity.ObservationEventEntity
import com.example.aleartmycontroller.data.local.entity.PhotoEntity
import com.example.aleartmycontroller.data.local.entity.RecordEntity
import com.example.aleartmycontroller.data.local.entity.RecordType
import com.example.aleartmycontroller.data.local.entity.amc.AmcAttachmentQueueEntity
import com.example.aleartmycontroller.data.local.entity.amc.AmcDraftRecordEntity
import com.example.aleartmycontroller.data.local.entity.amc.AmcOutboxEntity
import com.example.aleartmycontroller.data.local.entity.amc.AmcRecordRevisionEntity
import com.example.aleartmycontroller.data.local.entity.amc.AmcTypeConverters
import com.example.aleartmycontroller.data.local.entity.TogglPendingActionEntity
import com.example.aleartmycontroller.data.local.entity.TogglSyncStateEntity
import com.example.aleartmycontroller.data.local.entity.TogglTimeEntryCacheEntity

// ---- TypeConverters ----

class RecordTypeConverter {
    @TypeConverter
    fun fromRecordType(value: RecordType): String = value.name

    @TypeConverter
    fun toRecordType(value: String): RecordType = RecordType.valueOf(value)
}

// ---- Database ----

@Database(
    entities = [
        EventEntity::class,
        RecordEntity::class,
        PhotoEntity::class,
        MemoEntity::class,
        ObservationEventEntity::class,
        AmcDraftRecordEntity::class,
        AmcRecordRevisionEntity::class,
        AmcAttachmentQueueEntity::class,
        AmcOutboxEntity::class,
        TogglSyncStateEntity::class,
        TogglPendingActionEntity::class,
        TogglTimeEntryCacheEntity::class
    ],
    version = 6,
    exportSchema = true
)
@TypeConverters(RecordTypeConverter::class, AmcTypeConverters::class)
abstract class AppDatabase : RoomDatabase() {
    abstract fun analyticsDao(): AnalyticsDao
    abstract fun amcDraftRecordDao(): AmcDraftRecordDao
    abstract fun amcRecordRevisionDao(): AmcRecordRevisionDao
    abstract fun amcAttachmentQueueDao(): AmcAttachmentQueueDao
    abstract fun amcOutboxDao(): AmcOutboxDao
    abstract fun eventDao(): EventDao
    abstract fun observationEventDao(): ObservationEventDao
    abstract fun recordDao(): RecordDao
    abstract fun photoDao(): PhotoDao
    abstract fun memoDao(): MemoDao
    abstract fun togglSyncStateDao(): TogglSyncStateDao
    abstract fun togglPendingActionDao(): TogglPendingActionDao
    abstract fun togglTimeEntryCacheDao(): TogglTimeEntryCacheDao

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

        val MIGRATION_4_5 = object : Migration(4, 5) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL(
                    """
                    CREATE TABLE IF NOT EXISTS `toggl_sync_state` (
                        `id` INTEGER NOT NULL PRIMARY KEY,
                        `autoSyncEnabled` INTEGER NOT NULL,
                        `syncStatus` TEXT NOT NULL,
                        `lastSyncedAtMillis` INTEGER,
                        `lastAttemptAtMillis` INTEGER,
                        `lastErrorMessage` TEXT,
                        `defaultWorkspaceId` INTEGER
                    )
                    """.trimIndent()
                )
                db.execSQL(
                    """
                    CREATE TABLE IF NOT EXISTS `toggl_pending_actions` (
                        `actionId` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                        `actionType` TEXT NOT NULL,
                        `description` TEXT,
                        `tagsCsv` TEXT NOT NULL,
                        `createdAtMillis` INTEGER NOT NULL,
                        `attemptCount` INTEGER NOT NULL,
                        `lastAttemptAtMillis` INTEGER,
                        `lastErrorMessage` TEXT
                    )
                    """.trimIndent()
                )
                db.execSQL(
                    """
                    CREATE TABLE IF NOT EXISTS `toggl_time_entry_cache` (
                        `remoteId` INTEGER NOT NULL PRIMARY KEY,
                        `workspaceId` INTEGER NOT NULL,
                        `description` TEXT,
                        `startMillis` INTEGER NOT NULL,
                        `durationSeconds` INTEGER NOT NULL,
                        `tagsCsv` TEXT NOT NULL,
                        `syncedAtMillis` INTEGER NOT NULL
                    )
                    """.trimIndent()
                )
            }
        }

        val MIGRATION_5_6 = object : Migration(5, 6) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL(
                    """
                    CREATE TABLE IF NOT EXISTS `amc_draft_records` (
                        `draftRecordId` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                        `eventId` INTEGER,
                        `remoteRecordId` TEXT,
                        `ownerUserId` TEXT,
                        `currentBody` TEXT NOT NULL,
                        `visibility` TEXT NOT NULL,
                        `currentRevision` INTEGER NOT NULL,
                        `updatedAtMillis` INTEGER NOT NULL,
                        `createdAtMillis` INTEGER NOT NULL,
                        `deletedAtMillis` INTEGER,
                        `deletedByUserId` TEXT,
                        `source` TEXT NOT NULL,
                        `syncState` TEXT NOT NULL,
                        `idempotencyKey` TEXT NOT NULL
                    )
                    """.trimIndent()
                )
                db.execSQL(
                    "CREATE UNIQUE INDEX IF NOT EXISTS `index_amc_draft_records_remoteRecordId` ON `amc_draft_records`(`remoteRecordId`)"
                )
                db.execSQL(
                    "CREATE UNIQUE INDEX IF NOT EXISTS `index_amc_draft_records_idempotencyKey` ON `amc_draft_records`(`idempotencyKey`)"
                )
                db.execSQL(
                    "CREATE INDEX IF NOT EXISTS `index_amc_draft_records_eventId` ON `amc_draft_records`(`eventId`)"
                )
                db.execSQL(
                    "CREATE INDEX IF NOT EXISTS `index_amc_draft_records_syncState` ON `amc_draft_records`(`syncState`)"
                )
                db.execSQL(
                    """
                    CREATE TABLE IF NOT EXISTS `amc_record_revisions` (
                        `revisionId` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                        `draftRecordId` INTEGER NOT NULL,
                        `revisionNumber` INTEGER NOT NULL,
                        `bodySnapshot` TEXT NOT NULL,
                        `editorUserId` TEXT,
                        `changeSummary` TEXT,
                        `createdAtMillis` INTEGER NOT NULL,
                        `idempotencyKey` TEXT NOT NULL
                    )
                    """.trimIndent()
                )
                db.execSQL(
                    "CREATE INDEX IF NOT EXISTS `index_amc_record_revisions_draftRecordId` ON `amc_record_revisions`(`draftRecordId`)"
                )
                db.execSQL(
                    "CREATE UNIQUE INDEX IF NOT EXISTS `index_amc_record_revisions_idempotencyKey` ON `amc_record_revisions`(`idempotencyKey`)"
                )
                db.execSQL(
                    "CREATE UNIQUE INDEX IF NOT EXISTS `index_amc_record_revisions_draftRecordId_revisionNumber` ON `amc_record_revisions`(`draftRecordId`, `revisionNumber`)"
                )
                db.execSQL(
                    """
                    CREATE TABLE IF NOT EXISTS `amc_attachment_queue` (
                        `attachmentId` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                        `draftRecordId` INTEGER NOT NULL,
                        `type` TEXT NOT NULL,
                        `localUri` TEXT NOT NULL,
                        `r2Key` TEXT,
                        `mimeType` TEXT NOT NULL,
                        `sizeBytes` INTEGER NOT NULL,
                        `checksum` TEXT,
                        `status` TEXT NOT NULL,
                        `retryCount` INTEGER NOT NULL,
                        `lastErrorMessage` TEXT,
                        `uploadedAtMillis` INTEGER,
                        `readyAtMillis` INTEGER,
                        `createdAtMillis` INTEGER NOT NULL,
                        `updatedAtMillis` INTEGER NOT NULL,
                        `idempotencyKey` TEXT NOT NULL
                    )
                    """.trimIndent()
                )
                db.execSQL(
                    "CREATE INDEX IF NOT EXISTS `index_amc_attachment_queue_draftRecordId` ON `amc_attachment_queue`(`draftRecordId`)"
                )
                db.execSQL(
                    "CREATE INDEX IF NOT EXISTS `index_amc_attachment_queue_status` ON `amc_attachment_queue`(`status`)"
                )
                db.execSQL(
                    "CREATE UNIQUE INDEX IF NOT EXISTS `index_amc_attachment_queue_idempotencyKey` ON `amc_attachment_queue`(`idempotencyKey`)"
                )
                db.execSQL(
                    """
                    CREATE TABLE IF NOT EXISTS `amc_outbox_jobs` (
                        `jobId` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                        `jobType` TEXT NOT NULL,
                        `payloadJson` TEXT NOT NULL,
                        `state` TEXT NOT NULL,
                        `attemptCount` INTEGER NOT NULL,
                        `nextAttemptAtMillis` INTEGER NOT NULL,
                        `lastErrorMessage` TEXT,
                        `createdAtMillis` INTEGER NOT NULL,
                        `updatedAtMillis` INTEGER NOT NULL,
                        `idempotencyKey` TEXT NOT NULL
                    )
                    """.trimIndent()
                )
                db.execSQL(
                    "CREATE INDEX IF NOT EXISTS `index_amc_outbox_jobs_jobType` ON `amc_outbox_jobs`(`jobType`)"
                )
                db.execSQL(
                    "CREATE INDEX IF NOT EXISTS `index_amc_outbox_jobs_state` ON `amc_outbox_jobs`(`state`)"
                )
                db.execSQL(
                    "CREATE UNIQUE INDEX IF NOT EXISTS `index_amc_outbox_jobs_idempotencyKey` ON `amc_outbox_jobs`(`idempotencyKey`)"
                )
            }
        }
    }
}

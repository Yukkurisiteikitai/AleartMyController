package com.example.aleartmycontroller.migration

import androidx.sqlite.db.SupportSQLiteDatabase
import androidx.sqlite.db.SupportSQLiteOpenHelper
import androidx.sqlite.db.framework.FrameworkSQLiteOpenHelperFactory
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.example.aleartmycontroller.data.local.AppDatabase
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class Migration5To6Test {
    companion object {
        private val V5_DDL = listOf(
            """
            CREATE TABLE IF NOT EXISTS `events` (
                `eventId`       INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                `googleEventId` TEXT NOT NULL,
                `title`         TEXT NOT NULL,
                `startTime`     INTEGER NOT NULL,
                `endTime`       INTEGER NOT NULL
            )
            """,
            "CREATE UNIQUE INDEX IF NOT EXISTS `index_events_googleEventId` ON `events`(`googleEventId`)",
            """
            CREATE TABLE IF NOT EXISTS `records` (
                `recordId`   INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                `obsEventId` INTEGER NOT NULL,
                `recordTime` INTEGER NOT NULL,
                `recordType` TEXT NOT NULL,
                FOREIGN KEY(`obsEventId`) REFERENCES `observation_events`(`obsEventId`)
                    ON UPDATE NO ACTION ON DELETE CASCADE
            )
            """,
            "CREATE INDEX IF NOT EXISTS `index_records_obsEventId` ON `records`(`obsEventId`)",
            """
            CREATE TABLE IF NOT EXISTS `photos` (
                `photoId`  INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                `recordId` INTEGER NOT NULL,
                `filePath` TEXT NOT NULL,
                FOREIGN KEY(`recordId`) REFERENCES `records`(`recordId`)
                    ON UPDATE NO ACTION ON DELETE CASCADE
            )
            """,
            "CREATE INDEX IF NOT EXISTS `index_photos_recordId` ON `photos`(`recordId`)",
            """
            CREATE TABLE IF NOT EXISTS `memos` (
                `memoId`      INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                `recordId`    INTEGER NOT NULL,
                `memoText`    TEXT NOT NULL,
                `isVoiceMemo` INTEGER NOT NULL DEFAULT 0,
                FOREIGN KEY(`recordId`) REFERENCES `records`(`recordId`)
                    ON UPDATE NO ACTION ON DELETE CASCADE
            )
            """,
            "CREATE INDEX IF NOT EXISTS `index_memos_recordId` ON `memos`(`recordId`)",
            """
            CREATE TABLE IF NOT EXISTS `observation_events` (
                `obsEventId`    INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                `googleEventId` TEXT,
                `title`         TEXT NOT NULL,
                `startTime`     INTEGER NOT NULL,
                `endTime`       INTEGER NOT NULL
            )
            """,
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
            """,
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
            """,
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
            """
        )
    }

    private fun buildV5InMemoryDb(): SupportSQLiteDatabase {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val callback = object : SupportSQLiteOpenHelper.Callback(5) {
            override fun onCreate(db: SupportSQLiteDatabase) {
                V5_DDL.forEach { db.execSQL(it.trimIndent()) }
            }

            override fun onUpgrade(db: SupportSQLiteDatabase, oldVersion: Int, newVersion: Int) = Unit
        }
        val config = SupportSQLiteOpenHelper.Configuration
            .builder(context)
            .name(null)
            .callback(callback)
            .build()
        return FrameworkSQLiteOpenHelperFactory().create(config).writableDatabase
    }

    @Test
    fun migration_createsAmcTables() {
        val db = buildV5InMemoryDb()

        AppDatabase.MIGRATION_5_6.migrate(db)

        val tables = mutableSetOf<String>()
        db.query("SELECT name FROM sqlite_master WHERE type='table'").use { cursor ->
            while (cursor.moveToNext()) {
                tables += cursor.getString(0)
            }
        }

        assertTrue("amc_draft_records がない", "amc_draft_records" in tables)
        assertTrue("amc_record_revisions がない", "amc_record_revisions" in tables)
        assertTrue("amc_attachment_queue がない", "amc_attachment_queue" in tables)
        assertTrue("amc_outbox_jobs がない", "amc_outbox_jobs" in tables)
        db.close()
    }

    @Test
    fun migration_preservesExistingSchema() {
        val db = buildV5InMemoryDb()

        AppDatabase.MIGRATION_5_6.migrate(db)

        db.query("PRAGMA table_info(`records`)").use { cursor ->
            assertEquals(4, cursor.count)
        }
        db.close()
    }
}


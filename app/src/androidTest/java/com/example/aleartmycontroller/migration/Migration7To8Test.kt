package com.example.aleartmycontroller.migration

import androidx.sqlite.db.SupportSQLiteDatabase
import androidx.sqlite.db.SupportSQLiteOpenHelper
import androidx.sqlite.db.framework.FrameworkSQLiteOpenHelperFactory
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.example.aleartmycontroller.data.local.AppDatabase
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class Migration7To8Test {
    private fun buildV7InMemoryDb(): SupportSQLiteDatabase {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val callback = object : SupportSQLiteOpenHelper.Callback(7) {
            override fun onCreate(db: SupportSQLiteDatabase) {
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
                        `uploadSessionId` TEXT,
                        `attemptNumber` INTEGER NOT NULL DEFAULT 0,
                        `retryCount` INTEGER NOT NULL,
                        `lastErrorCode` TEXT,
                        `lastErrorMessage` TEXT,
                        `expiresAtMillis` INTEGER,
                        `uploadedAtMillis` INTEGER,
                        `readyAtMillis` INTEGER,
                        `createdAtMillis` INTEGER NOT NULL,
                        `updatedAtMillis` INTEGER NOT NULL,
                        `idempotencyKey` TEXT NOT NULL
                    )
                    """.trimIndent()
                )
                db.execSQL("CREATE INDEX IF NOT EXISTS `index_amc_attachment_queue_draftRecordId` ON `amc_attachment_queue`(`draftRecordId`)")
                db.execSQL("CREATE INDEX IF NOT EXISTS `index_amc_attachment_queue_status` ON `amc_attachment_queue`(`status`)")
                db.execSQL("CREATE UNIQUE INDEX IF NOT EXISTS `index_amc_attachment_queue_idempotencyKey` ON `amc_attachment_queue`(`idempotencyKey`)")
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
    fun migration_renamesR2KeyToStoragePath() {
        val db = buildV7InMemoryDb()

        AppDatabase.MIGRATION_7_8.migrate(db)

        val columns = mutableMapOf<String, String>()
        db.query("PRAGMA table_info(`amc_attachment_queue`)").use { cursor ->
            while (cursor.moveToNext()) {
                columns[cursor.getString(1)] = cursor.getString(2)
            }
        }

        assertTrue("storagePath column should exist", columns.containsKey("storagePath"))
        assertFalse("r2Key column should be removed", columns.containsKey("r2Key"))
    }

    @Test
    fun migration_preservesExistingData() {
        val db = buildV7InMemoryDb()
        db.execSQL(
            """
            INSERT INTO `amc_attachment_queue` (
                `attachmentId`, `draftRecordId`, `type`, `localUri`, `r2Key`, `mimeType`,
                `sizeBytes`, `checksum`, `status`, `uploadSessionId`, `attemptNumber`,
                `retryCount`, `lastErrorCode`, `lastErrorMessage`, `expiresAtMillis`,
                `uploadedAtMillis`, `readyAtMillis`, `createdAtMillis`, `updatedAtMillis`,
                `idempotencyKey`
            ) VALUES (1, 10, 'IMAGE', 'file:///tmp/demo.jpg', 'bucket/path/img.jpg', 'image/jpeg',
                42, NULL, 'READY', NULL, 1, 0, NULL, NULL, NULL, 1000, 1000, 1000, 1000, 'idem-1')
            """.trimIndent()
        )

        AppDatabase.MIGRATION_7_8.migrate(db)

        db.query("SELECT `storagePath`, `mimeType` FROM `amc_attachment_queue` WHERE attachmentId = 1").use { cursor ->
            assertTrue(cursor.moveToFirst())
            assertEquals("bucket/path/img.jpg", cursor.getString(0))
            assertEquals("image/jpeg", cursor.getString(1))
        }
        db.close()
    }

    @Test
    fun migration_preservesIndexes() {
        val db = buildV7InMemoryDb()
        AppDatabase.MIGRATION_7_8.migrate(db)

        val indexes = mutableSetOf<String>()
        db.query("PRAGMA index_list(`amc_attachment_queue`)").use { cursor ->
            while (cursor.moveToNext()) {
                indexes.add(cursor.getString(1))
            }
        }

        assertTrue(indexes.contains("index_amc_attachment_queue_draftRecordId"))
        assertTrue(indexes.contains("index_amc_attachment_queue_status"))
        assertTrue(indexes.contains("index_amc_attachment_queue_idempotencyKey"))
        db.close()
    }
}

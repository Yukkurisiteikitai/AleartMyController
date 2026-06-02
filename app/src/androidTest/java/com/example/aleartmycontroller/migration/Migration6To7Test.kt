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
class Migration6To7Test {
    private fun buildV6InMemoryDb(): SupportSQLiteDatabase {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val callback = object : SupportSQLiteOpenHelper.Callback(6) {
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
    fun migration_addsAttachmentAttemptColumns() {
        val db = buildV6InMemoryDb()

        AppDatabase.MIGRATION_6_7.migrate(db)

        val columns = mutableMapOf<String, String>()
        db.query("PRAGMA table_info(`amc_attachment_queue`)").use { cursor ->
            while (cursor.moveToNext()) {
                columns[cursor.getString(1)] = cursor.getString(2)
            }
        }

        assertEquals("TEXT", columns["uploadSessionId"])
        assertEquals("INTEGER", columns["attemptNumber"])
        assertEquals("TEXT", columns["lastErrorCode"])
        assertEquals("INTEGER", columns["expiresAtMillis"])
        db.close()
    }

    @Test
    fun migration_backfillsAttemptNumberToZero() {
        val db = buildV6InMemoryDb()
        db.execSQL(
            """
            INSERT INTO `amc_attachment_queue` (
                `attachmentId`, `draftRecordId`, `type`, `localUri`, `r2Key`, `mimeType`,
                `sizeBytes`, `checksum`, `status`, `retryCount`, `lastErrorMessage`,
                `uploadedAtMillis`, `readyAtMillis`, `createdAtMillis`, `updatedAtMillis`,
                `idempotencyKey`
            ) VALUES (1, 10, 'IMAGE', 'file:///tmp/demo.jpg', NULL, 'image/jpeg', 42, NULL,
                'PENDING', 0, NULL, NULL, NULL, 1000, 1000, 'idem-1')
            """.trimIndent()
        )

        AppDatabase.MIGRATION_6_7.migrate(db)

        db.query("SELECT attemptNumber FROM `amc_attachment_queue` WHERE attachmentId = 1").use { cursor ->
            assertTrue(cursor.moveToFirst())
            assertEquals(0, cursor.getInt(0))
        }
        db.close()
    }
}

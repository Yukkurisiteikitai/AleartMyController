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

/**
 * Migration 3→4 の SQL 正当性テスト。
 *
 * v3 スキーマ: records.eventId FK → events（CASCADE）
 * v4 スキーマ: records.obsEventId FK → observation_events（CASCADE）
 *
 * テスト戦略:
 *   Migration2To3Test と同じく、インメモリ SQLite に v3 DDL を手動構築し、
 *   AppDatabase.MIGRATION_3_4.migrate(db) を直接呼び出して SQL を検証する。
 *
 * カバーするケース:
 *   1. migration 後に obsEventId 列が存在すること
 *   2. migration 後に eventId 列が存在しないこと
 *   3. record の obsEventId が正しい observation_events 行を指すこと
 *   4. observation_events 未登録のイベントは catch-up で昇格されること
 *   5. 既存レコードが欠損なく移行されること（件数保持）
 *   6. index_records_obsEventId インデックスが作成されること
 *   7. observation_events に googleEventId のユニークインデックスが作成されること
 */
@RunWith(AndroidJUnit4::class)
class Migration3To4Test {

    // ─── V3 スキーマ定義 ──────────────────────────────────────────────────────

    companion object {
        private val V3_DDL = listOf(
            // events（変更なし）
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
            // records（v3: eventId FK → events）
            """
            CREATE TABLE IF NOT EXISTS `records` (
                `recordId`   INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                `eventId`    INTEGER NOT NULL,
                `recordTime` INTEGER NOT NULL,
                `recordType` TEXT NOT NULL,
                FOREIGN KEY(`eventId`) REFERENCES `events`(`eventId`)
                    ON UPDATE NO ACTION ON DELETE CASCADE
            )
            """,
            "CREATE INDEX IF NOT EXISTS `index_records_eventId` ON `records`(`eventId`)",
            // photos
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
            // memos
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
            // observation_events（v3 時点ではユニークインデックスなし）
            """
            CREATE TABLE IF NOT EXISTS `observation_events` (
                `obsEventId`    INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                `googleEventId` TEXT,
                `title`         TEXT NOT NULL,
                `startTime`     INTEGER NOT NULL,
                `endTime`       INTEGER NOT NULL
            )
            """
        )
    }

    // ─── ヘルパー ─────────────────────────────────────────────────────────────

    private fun buildV3InMemoryDb(): SupportSQLiteDatabase {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val callback = object : SupportSQLiteOpenHelper.Callback(3) {
            override fun onCreate(db: SupportSQLiteDatabase) {
                V3_DDL.forEach { db.execSQL(it.trimIndent()) }
            }
            override fun onUpgrade(db: SupportSQLiteDatabase, old: Int, new: Int) {}
        }
        val config = SupportSQLiteOpenHelper.Configuration
            .builder(context)
            .name(null)
            .callback(callback)
            .build()
        return FrameworkSQLiteOpenHelperFactory().create(config).writableDatabase
    }

    private fun SupportSQLiteDatabase.insertEvent(
        googleEventId: String,
        title: String,
        startTime: Long = 1_000L,
        endTime: Long = 2_000L
    ): Long {
        execSQL(
            "INSERT INTO events (googleEventId, title, startTime, endTime) VALUES (?, ?, ?, ?)",
            arrayOf(googleEventId, title, startTime, endTime)
        )
        return query("SELECT eventId FROM events WHERE googleEventId = ?", arrayOf(googleEventId))
            .use { it.moveToFirst(); it.getLong(0) }
    }

    private fun SupportSQLiteDatabase.insertObsEvent(
        googleEventId: String,
        title: String,
        startTime: Long = 1_000L,
        endTime: Long = 2_000L
    ): Long {
        execSQL(
            "INSERT INTO observation_events (googleEventId, title, startTime, endTime) VALUES (?, ?, ?, ?)",
            arrayOf(googleEventId, title, startTime, endTime)
        )
        return query(
            "SELECT obsEventId FROM observation_events WHERE googleEventId = ?",
            arrayOf(googleEventId)
        ).use { it.moveToFirst(); it.getLong(0) }
    }

    private fun SupportSQLiteDatabase.insertRecord(eventId: Long, type: String = "MEMO"): Long {
        execSQL(
            "INSERT INTO records (eventId, recordTime, recordType) VALUES (?, ?, ?)",
            arrayOf(eventId, System.currentTimeMillis(), type)
        )
        return query("SELECT last_insert_rowid()").use { it.moveToFirst(); it.getLong(0) }
    }

    private fun SupportSQLiteDatabase.columnNames(table: String): Set<String> {
        val cols = mutableSetOf<String>()
        query("PRAGMA table_info(`$table`)").use { c ->
            while (c.moveToNext()) cols.add(c.getString(c.getColumnIndexOrThrow("name")))
        }
        return cols
    }

    private fun SupportSQLiteDatabase.indexExists(indexName: String): Boolean {
        query(
            "SELECT name FROM sqlite_master WHERE type='index' AND name=?",
            arrayOf(indexName)
        ).use { return it.count > 0 }
    }

    // ─── テストケース ──────────────────────────────────────────────────────────

    /**
     * 1. migration 後に records テーブルが obsEventId 列を持つこと。
     */
    @Test
    fun migration_records_hasObsEventIdColumn() {
        val db = buildV3InMemoryDb()
        val eventId = db.insertEvent("g1", "E1")
        db.insertObsEvent("g1", "E1")
        db.insertRecord(eventId)

        AppDatabase.MIGRATION_3_4.migrate(db)

        assertTrue("obsEventId 列が存在しない", "obsEventId" in db.columnNames("records"))
        db.close()
    }

    /**
     * 2. migration 後に records テーブルが eventId 列を持たないこと。
     */
    @Test
    fun migration_records_doesNotHaveEventIdColumn() {
        val db = buildV3InMemoryDb()
        val eventId = db.insertEvent("g1", "E1")
        db.insertObsEvent("g1", "E1")
        db.insertRecord(eventId)

        AppDatabase.MIGRATION_3_4.migrate(db)

        assertFalse("eventId 列が残っている", "eventId" in db.columnNames("records"))
        db.close()
    }

    /**
     * 3. migration 後に record の obsEventId が正しい observation_events 行を指すこと。
     */
    @Test
    fun migration_record_obsEventIdPointsToCorrectObservationEvent() {
        val db = buildV3InMemoryDb()
        val eventId = db.insertEvent("g_check", "Check Event", 3_000L, 4_000L)
        val obsEventId = db.insertObsEvent("g_check", "Check Event", 3_000L, 4_000L)
        db.insertRecord(eventId)

        AppDatabase.MIGRATION_3_4.migrate(db)

        db.query("SELECT obsEventId FROM records").use { c ->
            assertTrue(c.moveToFirst())
            assertEquals(obsEventId, c.getLong(0))
        }
        db.close()
    }

    /**
     * 4. observation_events 未登録のイベント（catch-up 対象）が migration で昇格されること。
     */
    @Test
    fun migration_catchUp_promotesEventNotYetInObservationEvents() {
        val db = buildV3InMemoryDb()
        // observation_events には登録されていないが records は存在する
        val eventId = db.insertEvent("g_new", "New Event", 5_000L, 6_000L)
        db.insertRecord(eventId)
        // observation_events には別イベントしかない
        db.insertObsEvent("g_other", "Other")

        AppDatabase.MIGRATION_3_4.migrate(db)

        db.query(
            "SELECT * FROM observation_events WHERE googleEventId = 'g_new'"
        ).use { c ->
            assertEquals("catch-up 昇格行が1件であること", 1, c.count)
        }
        db.close()
    }

    /**
     * 5. 既存レコードが欠損なく移行されること（件数保持）。
     */
    @Test
    fun migration_preservesAllRecordRows() {
        val db = buildV3InMemoryDb()
        val e1 = db.insertEvent("g_a", "A")
        val e2 = db.insertEvent("g_b", "B")
        db.insertObsEvent("g_a", "A")
        db.insertObsEvent("g_b", "B")
        db.insertRecord(e1, "PHOTO")
        db.insertRecord(e1, "MEMO")
        db.insertRecord(e2, "PHOTO")

        AppDatabase.MIGRATION_3_4.migrate(db)

        db.query("SELECT COUNT(*) FROM records").use { c ->
            assertTrue(c.moveToFirst())
            assertEquals("レコード件数が保持されていない", 3, c.getInt(0))
        }
        db.close()
    }

    /**
     * 6. index_records_obsEventId インデックスが作成されること。
     */
    @Test
    fun migration_createsObsEventIdIndex() {
        val db = buildV3InMemoryDb()
        AppDatabase.MIGRATION_3_4.migrate(db)
        assertTrue(
            "index_records_obsEventId が存在しない",
            db.indexExists("index_records_obsEventId")
        )
        db.close()
    }

    /**
     * 7. observation_events に googleEventId のユニークインデックスが作成されること。
     */
    @Test
    fun migration_createsUniqueIndexOnObservationEventsGoogleEventId() {
        val db = buildV3InMemoryDb()
        AppDatabase.MIGRATION_3_4.migrate(db)
        assertTrue(
            "index_observation_events_googleEventId が存在しない",
            db.indexExists("index_observation_events_googleEventId")
        )
        db.close()
    }
}

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

/**
 * Migration 2→3 の SQL 正当性テスト。
 *
 * テスト戦略:
 *   Room の MigrationTestHelper ではなく、インメモリ SQLite を直接操作することで
 *   エクスポート済みスキーマ JSON に依存せず単独で動作する。
 *   AppDatabase.MIGRATION_2_3.migrate(db) を呼び出すことで、
 *   本番と同じ Migration オブジェクトの SQL を検証する。
 *
 * カバーするケース:
 *   1. observation_events テーブルが作成されること
 *   2. records を持つ event が observation_events に昇格されること
 *   3. records を持たない event は昇格されないこと
 *   4. records が複数あっても observation_events の行は1件であること
 *   5. スナップショット値（title / startTime / endTime）が正確にコピーされること
 *   6. 有り・無しが混在する場合に有りのみが昇格されること
 *   7. CREATE TABLE の IF NOT EXISTS により二重実行しても例外が出ないこと
 */
@RunWith(AndroidJUnit4::class)
class Migration2To3Test {

    // ─── V2 スキーマ定義 ──────────────────────────────────────────────────────
    // MigrationTestHelper のスキーマ JSON に依存せず、エンティティ定義から
    // 直接 SQL を再現する。変更があれば合わせて更新すること。

    companion object {
        private val V2_DDL = listOf(
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
                `eventId`    INTEGER NOT NULL,
                `recordTime` INTEGER NOT NULL,
                `recordType` TEXT NOT NULL,
                FOREIGN KEY(`eventId`) REFERENCES `events`(`eventId`)
                    ON UPDATE NO ACTION ON DELETE CASCADE
            )
            """,
            "CREATE INDEX IF NOT EXISTS `index_records_eventId` ON `records`(`eventId`)",
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
            "CREATE INDEX IF NOT EXISTS `index_memos_recordId` ON `memos`(`recordId`)"
        )
    }

    // ─── ヘルパー ─────────────────────────────────────────────────────────────

    /** V2 スキーマのインメモリ SupportSQLiteDatabase を返す。 */
    private fun buildV2InMemoryDb(): SupportSQLiteDatabase {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val callback = object : SupportSQLiteOpenHelper.Callback(2) {
            override fun onCreate(db: SupportSQLiteDatabase) {
                V2_DDL.forEach { db.execSQL(it.trimIndent()) }
            }
            override fun onUpgrade(db: SupportSQLiteDatabase, old: Int, new: Int) {}
        }
        val config = SupportSQLiteOpenHelper.Configuration
            .builder(context)
            .name(null) // in-memory
            .callback(callback)
            .build()
        return FrameworkSQLiteOpenHelperFactory().create(config).writableDatabase
    }

    /** events にレコードを挿入し、自動採番された eventId を返す。 */
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

    /** records に1件挿入する。 */
    private fun SupportSQLiteDatabase.insertRecord(eventId: Long, type: String = "MEMO") {
        execSQL(
            "INSERT INTO records (eventId, recordTime, recordType) VALUES (?, ?, ?)",
            arrayOf(eventId, System.currentTimeMillis(), type)
        )
    }

    // ─── テストケース ──────────────────────────────────────────────────────────

    /**
     * 1. observation_events テーブルが作成されること。
     */
    @Test
    fun migration_createsObservationEventsTable() {
        val db = buildV2InMemoryDb()

        AppDatabase.MIGRATION_2_3.migrate(db)

        val cursor = db.query(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='observation_events'"
        )
        cursor.use { assertEquals("observation_events テーブルが存在しない", 1, it.count) }

        db.close()
    }

    /**
     * 2. records を持つ event が observation_events に昇格されること。
     */
    @Test
    fun migration_promotesEventThatHasRecords() {
        val db = buildV2InMemoryDb()
        val eventId = db.insertEvent("g_observed", "観察イベント", startTime = 3_000L, endTime = 4_000L)
        db.insertRecord(eventId)

        AppDatabase.MIGRATION_2_3.migrate(db)

        db.query("SELECT * FROM observation_events WHERE googleEventId = 'g_observed'").use { c ->
            assertEquals("昇格行が1件であること", 1, c.count)
            assertTrue(c.moveToFirst())
            assertEquals("観察イベント", c.getString(c.getColumnIndexOrThrow("title")))
            assertEquals(3_000L, c.getLong(c.getColumnIndexOrThrow("startTime")))
            assertEquals(4_000L, c.getLong(c.getColumnIndexOrThrow("endTime")))
        }

        db.close()
    }

    /**
     * 3. records を持たない event は observation_events に昇格されないこと。
     */
    @Test
    fun migration_doesNotPromoteEventWithoutRecords() {
        val db = buildV2InMemoryDb()
        db.insertEvent("g_empty", "未観察イベント")
        // records を挿入しない

        AppDatabase.MIGRATION_2_3.migrate(db)

        db.query("SELECT * FROM observation_events").use { c ->
            assertEquals("昇格行がないこと", 0, c.count)
        }

        db.close()
    }

    /**
     * 4. 同一 event に records が複数あっても observation_events は1件だけ作られること。
     */
    @Test
    fun migration_eventWithMultipleRecordsProducesExactlyOneRow() {
        val db = buildV2InMemoryDb()
        val eventId = db.insertEvent("g_multi", "複数記録イベント")
        db.insertRecord(eventId, "PHOTO")
        db.insertRecord(eventId, "MEMO")
        db.insertRecord(eventId, "PHOTO")

        AppDatabase.MIGRATION_2_3.migrate(db)

        db.query("SELECT * FROM observation_events WHERE googleEventId = 'g_multi'").use { c ->
            assertEquals("DISTINCT により昇格行は1件であること", 1, c.count)
        }

        db.close()
    }

    /**
     * 5. records 有り・無しが混在する場合、records 有りのみが昇格されること。
     */
    @Test
    fun migration_onlyPromotesEventsWithRecords_whenMixed() {
        val db = buildV2InMemoryDb()
        val observed = db.insertEvent("g_has", "観察済み", startTime = 100L, endTime = 200L)
        db.insertEvent("g_not", "未観察")
        db.insertRecord(observed)

        AppDatabase.MIGRATION_2_3.migrate(db)

        db.query("SELECT googleEventId FROM observation_events").use { c ->
            assertEquals("昇格行は1件のみ", 1, c.count)
            assertTrue(c.moveToFirst())
            assertEquals("g_has", c.getString(0))
        }

        db.close()
    }

    /**
     * 6. events が空のとき、migration は例外なく完了し observation_events も空であること。
     */
    @Test
    fun migration_succeeds_whenEventsTableIsEmpty() {
        val db = buildV2InMemoryDb()
        // 何も挿入しない

        AppDatabase.MIGRATION_2_3.migrate(db)

        db.query("SELECT * FROM observation_events").use { c ->
            assertEquals("空テーブルであること", 0, c.count)
        }

        db.close()
    }

    /**
     * 7. CREATE TABLE IF NOT EXISTS のため、migration SQL を再実行しても例外が出ないこと。
     *    （本番では起こらないが、SQL の冪等性を保証する）
     */
    @Test
    fun migration_createTableStatement_isIdempotent() {
        val db = buildV2InMemoryDb()
        AppDatabase.MIGRATION_2_3.migrate(db)

        // CREATE TABLE だけ再実行 — IF NOT EXISTS により例外なし
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

        db.close()
        // 例外が出なければ pass
    }
}

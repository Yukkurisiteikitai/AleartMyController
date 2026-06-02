// P1 データ層テスト: drift スキーマと §9 不変条件を in-memory DB で検証する。

import 'package:amc/data/local/amc_tables.dart';
import 'package:amc/data/local/database.dart';
import 'package:amc/data/local/tables.dart';
// drift も isNull/isNotNull を export するため matcher 側と衝突する。drift 側を隠す。
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  // 共通: event + observation_event(同じ googleEventId) + record + photo を作る。
  Future<({int eventId, int obsEventId, int recordId})> seedPhotoRecord({
    String googleId = 'g-1',
    int recordTime = 1000,
  }) async {
    final eventId = await db.eventDao.upsert(
      EventsCompanion.insert(
        googleEventId: googleId,
        title: 'Meeting',
        startTime: 0,
        endTime: 10000,
      ),
    );
    final obsEventId = await db.observationEventDao.insertOrIgnore(
      ObservationEventsCompanion.insert(
        googleEventId: Value(googleId),
        title: 'Meeting',
        startTime: 0,
        endTime: 10000,
      ),
    );
    final recordId = await db.recordDao.insertRecord(
      RecordsCompanion.insert(
        obsEventId: obsEventId,
        recordTime: recordTime,
        recordType: RecordType.photo,
      ),
    );
    await db.photoDao.insertPhoto(
      PhotosCompanion.insert(recordId: recordId, filePath: '/tmp/a.jpg'),
    );
    return (eventId: eventId, obsEventId: obsEventId, recordId: recordId);
  }

  test('watchByEventWithAttachments resolves events→observation_events→records JOIN', () async {
    final ids = await seedPhotoRecord();
    final rows = await db.recordDao.watchByEventWithAttachments(ids.eventId).first;
    expect(rows, hasLength(1));
    expect(rows.first.record.recordType, RecordType.photo);
    expect(rows.first.photos, hasLength(1));
    expect(rows.first.memos, isEmpty);
  });

  test('countByEvents returns per-event photo/memo badge counts (LEFT JOIN)', () async {
    final ids = await seedPhotoRecord();
    // 記録のないイベントも 0 で返る。
    final emptyEventId = await db.eventDao.upsert(
      EventsCompanion.insert(
        googleEventId: 'g-empty',
        title: 'Empty',
        startTime: 0,
        endTime: 1,
      ),
    );
    final counts =
        await db.recordDao.countByEvents([ids.eventId, emptyEventId]);
    final byId = {for (final c in counts) c.eventId: c};
    expect(byId[ids.eventId]!.photoCount, 1);
    expect(byId[ids.eventId]!.memoCount, 0);
    expect(byId[emptyEventId]!.photoCount, 0);
  });

  test('§9: deleting observation_event CASCADEs to records and photos', () async {
    final ids = await seedPhotoRecord();
    await (db.delete(db.observationEvents)
          ..where((t) => t.obsEventId.equals(ids.obsEventId)))
        .go();
    expect(await db.recordDao.findById(ids.recordId), isNull);
    final photos = await db.photoDao.findByRecord(ids.recordId);
    expect(photos, isEmpty);
  });

  test('§9: deleting an event (calendar cache) does NOT remove records', () async {
    final ids = await seedPhotoRecord();
    await db.eventDao.deleteById(ids.eventId);
    // records は observation_events を参照し events は参照しないため残る。
    expect(await db.recordDao.findById(ids.recordId), isNotNull);
  });

  test('§9: insertOrIgnore keeps existing row on duplicate googleEventId', () async {
    await db.observationEventDao.insertOrIgnore(
      ObservationEventsCompanion.insert(
        googleEventId: const Value('dup'),
        title: 'first',
        startTime: 0,
        endTime: 1,
      ),
    );
    await db.observationEventDao.insertOrIgnore(
      ObservationEventsCompanion.insert(
        googleEventId: const Value('dup'),
        title: 'second',
        startTime: 0,
        endTime: 1,
      ),
    );
    final found = await db.observationEventDao.findByGoogleEventId('dup');
    expect(found, isNotNull);
    expect(found!.title, 'first'); // 既存行が保持される
  });

  test('§9: deleteStaleEvents excludes local-draft:% and keeps active ids', () async {
    await db.eventDao.upsert(EventsCompanion.insert(
        googleEventId: 'local-draft:abc', title: 'draft', startTime: 0, endTime: 1));
    await db.eventDao.upsert(EventsCompanion.insert(
        googleEventId: 'keep', title: 'keep', startTime: 0, endTime: 1));
    await db.eventDao.upsert(EventsCompanion.insert(
        googleEventId: 'stale', title: 'stale', startTime: 0, endTime: 1));

    await db.eventDao.deleteStaleEvents(['keep']);

    expect(await db.eventDao.findByGoogleId('local-draft:abc'), isNotNull);
    expect(await db.eventDao.findByGoogleId('keep'), isNotNull);
    expect(await db.eventDao.findByGoogleId('stale'), isNull);
  });

  test('amc revision insert is idempotent on idempotency_key', () async {
    final draftId = await db.amcDraftDao.insertDraft(
      AmcDraftRecordsCompanion.insert(
        syncState: AmcSyncState.draft,
        updatedAtMillis: 0,
      ),
    );
    await db.amcDraftDao.insertRevisionOrIgnore(
      AmcRecordRevisionsCompanion.insert(
        draftRecordId: draftId,
        body: 'v1',
        idempotencyKey: 'key-1',
        createdAtMillis: 1,
      ),
    );
    await db.amcDraftDao.insertRevisionOrIgnore(
      AmcRecordRevisionsCompanion.insert(
        draftRecordId: draftId,
        body: 'v1-dup',
        idempotencyKey: 'key-1', // 同じキー → 無視される
        createdAtMillis: 2,
      ),
    );
    final latest = await db.amcDraftDao.findLatestRevisionForDraft(draftId);
    expect(latest!.body, 'v1'); // 重複は挿入されない
  });
}

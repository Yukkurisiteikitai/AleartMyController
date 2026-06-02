// P2 Repository テスト（ローカル完結部分）。Supabase/Calendar は介さない。

import 'package:amc/data/local/database.dart';
import 'package:amc/data/local/tables.dart';
import 'package:amc/data/repository/observation_event_repository.dart';
import 'package:amc/data/repository/record_repository.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ObservationEventRepository obsRepo;
  late RecordRepository recordRepo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    obsRepo = ObservationEventRepository(db.observationEventDao);
    recordRepo = RecordRepository(
      db: db,
      recordDao: db.recordDao,
      photoDao: db.photoDao,
      memoDao: db.memoDao,
      observationEventRepository: obsRepo,
    );
  });

  tearDown(() async => db.close());

  Future<Event> seedEvent({String googleId = 'g-1'}) async {
    final id = await db.eventDao.upsert(
      EventsCompanion.insert(
        googleEventId: googleId,
        title: 'Meeting',
        startTime: 0,
        endTime: 10000,
      ),
    );
    return (await db.eventDao.findById(id))!;
  }

  test('findOrCreate is idempotent: same googleEventId returns same obsEventId', () async {
    final event = await seedEvent();
    final a = await obsRepo.findOrCreate(event);
    final b = await obsRepo.findOrCreate(event);
    expect(a, b);
  });

  test('addPhotoRecord writes record + photo and resolves obsEventId', () async {
    final event = await seedEvent();
    final recordId = await recordRepo.addPhotoRecord(event, '/tmp/a.jpg');

    final rec = await recordRepo.findRecordById(recordId);
    expect(rec, isNotNull);
    expect(rec!.recordType, RecordType.photo);

    final photos = await recordRepo.getPhotosForRecord(recordId);
    expect(photos.single.filePath, '/tmp/a.jpg');

    // observation_event が1件作られている。
    final obs = await db.observationEventDao.findByGoogleEventId('g-1');
    expect(obs, isNotNull);
    expect(rec.obsEventId, obs!.obsEventId);
  });

  test('addMemoRecord normalizes (trims) body and flags voice', () async {
    final event = await seedEvent();
    final recordId =
        await recordRepo.addMemoRecord(event, '  hello  ', isVoice: true);
    final memos = await recordRepo.getMemosForRecord(recordId);
    expect(memos.single.memoText, 'hello'); // trim 済み
    expect(memos.single.isVoiceMemo, isTrue);
  });

  test('two photo records on same event share one observation_event', () async {
    final event = await seedEvent();
    final r1 = await recordRepo.addPhotoRecord(event, '/a.jpg');
    final r2 = await recordRepo.addPhotoRecord(event, '/b.jpg');
    final rec1 = await recordRepo.findRecordById(r1);
    final rec2 = await recordRepo.findRecordById(r2);
    expect(rec1!.obsEventId, rec2!.obsEventId);

    // バッジ集計: photo=2, memo=0
    final counts = await db.recordDao.countByEvents([event.eventId]);
    expect(counts.single.photoCount, 2);
    expect(counts.single.memoCount, 0);
  });
}

// 名前付き引数 + private フィールドのため initializing formal は使えない（言語仕様）。
// ignore_for_file: prefer_initializing_formals
import 'package:drift/drift.dart' show Value;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/content_policy.dart';
import '../local/amc_tables.dart';
import '../local/daos/amc_draft_dao.dart';
import '../local/daos/memo_dao.dart';
import '../local/daos/photo_dao.dart';
import '../local/daos/record_dao.dart';
import '../local/database.dart';
import '../local/tables.dart';
import 'observation_event_repository.dart';

/// 記録（写真・メモ）の追加と監視（Android: RecordRepository 相当）。
class RecordRepository {
  RecordRepository({
    required AppDatabase db,
    required RecordDao recordDao,
    required PhotoDao photoDao,
    required MemoDao memoDao,
    required ObservationEventRepository observationEventRepository,
    required AmcDraftDao amcDraftDao,
  })  : _db = db,
        _recordDao = recordDao,
        _photoDao = photoDao,
        _memoDao = memoDao,
        _obsRepo = observationEventRepository,
        _draftDao = amcDraftDao;

  final AppDatabase _db;
  final RecordDao _recordDao;
  final PhotoDao _photoDao;
  final MemoDao _memoDao;
  final ObservationEventRepository _obsRepo;
  final AmcDraftDao _draftDao;

  // ---- 監視（呼び出し側は引き続き Event.eventId を渡せる）----

  Stream<List<Record>> watchRecordsByEvent(int eventId) =>
      _recordDao.watchByEvent(eventId);

  Stream<List<RecordWithAttachments>> watchRecordsByEventWithAttachments(
          int eventId) =>
      _recordDao.watchByEventWithAttachments(eventId);

  Stream<List<Record>> watchAllRecords() => _recordDao.watchAll();

  Stream<List<RecordWithAttachments>> watchAllRecordsWithAttachments() =>
      _recordDao.watchAllWithAttachments();

  Future<Record?> findRecordById(int recordId) => _recordDao.findById(recordId);

  // ---- 記録追加（§9: record と添付を 1 トランザクションで）----

  /// 写真記録を追加する。record + photo を同一トランザクションで保存する。
  Future<int> addPhotoRecord(Event event, String filePath) {
    return _db.transaction(() async {
      final obsEventId = await _obsRepo.findOrCreate(event);
      final recordId = await _recordDao.insertRecord(
        RecordsCompanion.insert(
          obsEventId: obsEventId,
          recordTime: DateTime.now().millisecondsSinceEpoch,
          recordType: RecordType.photo,
        ),
      );
      await _photoDao.insertPhoto(
        PhotosCompanion.insert(recordId: recordId, filePath: filePath),
      );
      return recordId;
    });
  }

  /// テキスト／音声メモ記録を追加する。本文は NFC 正規化する(§9)。
  Future<int> addMemoRecord(Event event, String text, {bool isVoice = false}) {
    final normalized = AmcContentPolicy.normalizeBodyForStorage(text);
    return _db.transaction(() async {
      final obsEventId = await _obsRepo.findOrCreate(event);
      final recordId = await _recordDao.insertRecord(
        RecordsCompanion.insert(
          obsEventId: obsEventId,
          recordTime: DateTime.now().millisecondsSinceEpoch,
          recordType: RecordType.memo,
        ),
      );
      await _memoDao.insertMemo(
        MemosCompanion.insert(
          recordId: recordId,
          memoText: normalized,
          isVoiceMemo: Value(isVoice),
        ),
      );
      return recordId;
    });
  }

  Future<void> deleteRecord(int recordId) => _recordDao.deleteById(recordId);

  Future<List<Photo>> getPhotosForRecord(int recordId) =>
      _photoDao.findByRecord(recordId);

  Future<List<Memo>> getMemosForRecord(int recordId) =>
      _memoDao.findByRecord(recordId);

  /// Cloud→Local pull: Supabase の amc_records からテキスト記録を差分取得してローカルに保存する。
  ///
  /// - client が null（未初期化）またはサインイン前の場合は何もしない。
  /// - remoteRecordId で重複チェックし、既にローカルに存在するレコードはスキップする。
  /// - テキスト(current_body)が空のレコード（添付のみ）は今回対象外。
  Future<void> pullFromCloud(SupabaseClient? client) async {
    if (client == null) return;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    final rows = await client
        .from('amc_records')
        .select('id, google_calendar_event_id, current_body, created_at')
        .eq('owner_user_id', userId)
        .isFilter('deleted_at', null);

    if (rows.isEmpty) return;

    final existingIds = await _draftDao.getExistingRemoteRecordIds();

    for (final row in rows) {
      final remoteId = row['id'] as String;
      if (existingIds.contains(remoteId)) continue;

      final currentBody = (row['current_body'] as String?) ?? '';
      if (currentBody.isEmpty) continue;

      final googleEventId = row['google_calendar_event_id'] as String?;
      final createdAtMillis = DateTime.parse(row['created_at'] as String)
          .millisecondsSinceEpoch;

      final effectiveGoogleId = googleEventId ?? 'cloud:$remoteId';
      final obsTitle = currentBody.length > 50
          ? '${currentBody.substring(0, 50)}…'
          : currentBody;

      final obsEventId = await _obsRepo.findOrCreateByRaw(
        googleEventId: effectiveGoogleId,
        title: obsTitle,
        startTime: createdAtMillis,
        endTime: createdAtMillis,
      );

      await _db.transaction(() async {
        final recordId = await _recordDao.insertRecord(
          RecordsCompanion.insert(
            obsEventId: obsEventId,
            recordTime: createdAtMillis,
            recordType: RecordType.memo,
          ),
        );
        await _memoDao.insertMemo(
          MemosCompanion.insert(
            recordId: recordId,
            memoText: AmcContentPolicy.normalizeBodyForStorage(currentBody),
          ),
        );
        await _draftDao.insertDraft(
          AmcDraftRecordsCompanion.insert(
            obsEventId: Value(obsEventId),
            syncState: AmcSyncState.synced,
            remoteRecordId: Value(remoteId),
            currentBody: Value(currentBody),
            updatedAtMillis: createdAtMillis,
          ),
        );
      });
    }
  }
}

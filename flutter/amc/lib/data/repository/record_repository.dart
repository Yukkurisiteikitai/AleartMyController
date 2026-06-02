// 名前付き引数 + private フィールドのため initializing formal は使えない（言語仕様）。
// ignore_for_file: prefer_initializing_formals
import 'package:drift/drift.dart' show Value;

import '../../core/content_policy.dart';
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
  })  : _db = db,
        _recordDao = recordDao,
        _photoDao = photoDao,
        _memoDao = memoDao,
        _obsRepo = observationEventRepository;

  final AppDatabase _db;
  final RecordDao _recordDao;
  final PhotoDao _photoDao;
  final MemoDao _memoDao;
  final ObservationEventRepository _obsRepo;

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
}

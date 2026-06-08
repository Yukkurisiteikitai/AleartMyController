// 名前付き引数 + private フィールドのため initializing formal は使えない（言語仕様）。
// ignore_for_file: prefer_initializing_formals
import 'package:drift/drift.dart' show Value;

import '../../core/amc_idempotency.dart';
import '../../core/content_policy.dart';
import '../local/amc_tables.dart';
import '../local/daos/amc_attachment_dao.dart';
import '../local/daos/amc_draft_dao.dart';
import '../local/database.dart';
import 'amc_work_scheduler.dart';

/// AMC ローカル下書き・リビジョン・添付キューの管理（Android: AmcDraftRepository 相当）。
///
/// 本リポジトリは「クラウド同期パイプラインへの入口」。実際の Postgrest / Storage
/// 書き込みは worker（P4）が行う。ここでは Room(drift) への書き込みと worker 起動のみ。
class AmcDraftRepository {
  AmcDraftRepository({
    required AppDatabase db,
    required AmcDraftDao draftDao,
    required AmcAttachmentDao attachmentDao,
    required AmcWorkScheduler scheduler,
  })  : _db = db,
        _draftDao = draftDao,
        _attachmentDao = attachmentDao,
        _scheduler = scheduler;

  final AppDatabase _db;
  final AmcDraftDao _draftDao;
  final AmcAttachmentDao _attachmentDao;
  final AmcWorkScheduler _scheduler;

  Stream<int> watchUnsyncedCount() => _draftDao.watchUnsyncedCount();

  /// イベント(obsEventId)に対する下書きを取得、なければ作成して draftRecordId を返す。
  Future<int> getOrCreateDraftForEvent(int obsEventId) async {
    final existing = await _draftDao.findByObsEventId(obsEventId);
    if (existing != null) return existing.draftRecordId;
    return _draftDao.insertDraft(
      AmcDraftRecordsCompanion.insert(
        obsEventId: Value(obsEventId),
        syncState: AmcSyncState.draft,
        updatedAtMillis: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  /// 本文リビジョンを追記し、下書きを同期キュー(QUEUED)に載せて同期 worker を起動する。
  ///
  /// 不変条件(§9): revision insert と current_body 更新は同一トランザクション。
  /// idempotency_key により再送で重複行を作らない。本文は NFC 正規化する。
  Future<void> appendRevision(int draftRecordId, String newBody) async {
    final normalized = AmcContentPolicy.normalizeBodyForStorage(newBody);
    var changed = false;
    await _db.transaction(() async {
      final draft = await _draftDao.findById(draftRecordId);
      if (draft == null) {
        throw StateError('Draft not found: $draftRecordId');
      }
      if (draft.currentBody == normalized) return; // 変更なし
      final now = DateTime.now().millisecondsSinceEpoch;
      await _draftDao.insertRevisionOrIgnore(
        AmcRecordRevisionsCompanion.insert(
          draftRecordId: draftRecordId,
          body: normalized,
          idempotencyKey: AmcIdempotency.newKey(),
          createdAtMillis: now,
        ),
      );
      await _draftDao.updateBodyAndQueue(draftRecordId, normalized, now);
      changed = true;
    });
    if (changed) {
      await _scheduler.enqueueRecordSync();
    }
  }

  /// 添付をキューに積み（PENDING）、アップロード worker を起動する。
  /// 不変条件(§9): MIME は whitelist 制。
  Future<int> queueAttachment({
    required int draftRecordId,
    required String localUri,
    required String mimeType,
    String? checksum,
  }) async {
    if (!AmcContentPolicy.isAllowedAttachmentMime(mimeType)) {
      throw ArgumentError('Unsupported MIME type: $mimeType');
    }
    final id = await _attachmentDao.enqueue(
      AmcAttachmentQueueCompanion.insert(
        draftRecordId: draftRecordId,
        localUri: localUri,
        mimeType: mimeType.toLowerCase(),
        state: AmcAttachmentState.pending,
        checksum: Value(checksum),
      ),
    );
    await _scheduler.enqueueAttachmentUpload();
    return id;
  }

  /// サーバー同期完了の記録（worker から呼ぶ）。
  Future<void> markRecordSynced(
    int draftRecordId, {
    String? remoteRecordId,
    String? currentRevisionId,
  }) =>
      _draftDao.markSynced(
        draftRecordId,
        remoteRecordId: remoteRecordId,
        currentRevisionId: currentRevisionId,
      );

  /// Google Calendar ミラー本文を生成する（長文退避込み）。
  String buildCalendarMirrorBody(String body, {String? referenceUrl}) =>
      AmcContentPolicy.buildCalendarMirrorBody(body, referenceUrl: referenceUrl);
}

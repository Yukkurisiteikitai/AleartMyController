import 'package:drift/drift.dart';

import '../amc_tables.dart';
import '../database.dart';

part 'amc_draft_dao.g.dart';

@DriftAccessor(tables: [AmcDraftRecords, AmcRecordRevisions])
class AmcDraftDao extends DatabaseAccessor<AppDatabase>
    with _$AmcDraftDaoMixin {
  AmcDraftDao(super.attachedDatabase);

  // ---- draft ----

  Future<int> insertDraft(AmcDraftRecordsCompanion draft) =>
      into(amcDraftRecords).insert(draft);

  Future<AmcDraftRecord?> findById(int draftRecordId) =>
      (select(amcDraftRecords)
            ..where((t) => t.draftRecordId.equals(draftRecordId)))
          .getSingleOrNull();

  Future<AmcDraftRecord?> findByObsEventId(int obsEventId) =>
      (select(amcDraftRecords)
            ..where((t) => t.obsEventId.equals(obsEventId) & t.deleted.equals(false))
            ..limit(1))
          .getSingleOrNull();

  /// 同期待ち（syncState = queued）の下書きを一括取得（AmcRecordSyncWorker 用）。
  Future<List<AmcDraftRecord>> getPendingSyncOnce() {
    return (select(amcDraftRecords)
          ..where((t) =>
              t.syncState.equalsValue(AmcSyncState.queued) &
              t.deleted.equals(false)))
        .get();
  }

  /// 未同期件数の監視（設定画面のローカルキュー要約用）。
  Stream<int> watchUnsyncedCount() {
    final count = amcDraftRecords.draftRecordId.count();
    final query = selectOnly(amcDraftRecords)
      ..addColumns([count])
      ..where(amcDraftRecords.syncState.equalsValue(AmcSyncState.queued) &
          amcDraftRecords.deleted.equals(false));
    return query.map((row) => row.read(count) ?? 0).watchSingle();
  }

  Future<void> updateBodyAndQueue(int draftRecordId, String currentBody, int updatedAtMillis) {
    return (update(amcDraftRecords)
          ..where((t) => t.draftRecordId.equals(draftRecordId)))
        .write(AmcDraftRecordsCompanion(
      currentBody: Value(currentBody),
      syncState: const Value(AmcSyncState.queued),
      updatedAtMillis: Value(updatedAtMillis),
    ));
  }

  /// サーバー同期完了。remoteRecordId / currentRevisionId を確定し syncState=synced。
  Future<void> markSynced(
    int draftRecordId, {
    String? remoteRecordId,
    String? currentRevisionId,
  }) {
    return (update(amcDraftRecords)
          ..where((t) => t.draftRecordId.equals(draftRecordId)))
        .write(AmcDraftRecordsCompanion(
      syncState: const Value(AmcSyncState.synced),
      remoteRecordId:
          remoteRecordId == null ? const Value.absent() : Value(remoteRecordId),
      currentRevisionId: currentRevisionId == null
          ? const Value.absent()
          : Value(currentRevisionId),
    ));
  }

  /// クラウド pull の重複チェック用：既存 remoteRecordId の Set を返す。
  Future<Set<String>> getExistingRemoteRecordIds() async {
    final rows = await (select(amcDraftRecords)
          ..where((t) => t.remoteRecordId.isNotNull()))
        .get();
    return {for (final r in rows) if (r.remoteRecordId != null) r.remoteRecordId!};
  }

  Future<void> markFailed(int draftRecordId) {
    return (update(amcDraftRecords)
          ..where((t) => t.draftRecordId.equals(draftRecordId)))
        .write(const AmcDraftRecordsCompanion(syncState: Value(AmcSyncState.failed)));
  }

  /// remoteRecordId のみ確定（attachments INSERT 前に必要）。
  Future<void> setRemoteRecordId(int draftRecordId, String remoteRecordId) {
    return (update(amcDraftRecords)
          ..where((t) => t.draftRecordId.equals(draftRecordId)))
        .write(AmcDraftRecordsCompanion(remoteRecordId: Value(remoteRecordId)));
  }

  // ---- revisions ----

  /// リビジョン追記。idempotency_key が UNIQUE のため重複時は IGNORE（冪等）。
  Future<int> insertRevisionOrIgnore(AmcRecordRevisionsCompanion revision) =>
      into(amcRecordRevisions)
          .insert(revision, mode: InsertMode.insertOrIgnore);

  Future<AmcRecordRevision?> findLatestRevisionForDraft(int draftRecordId) {
    return (select(amcRecordRevisions)
          ..where((t) => t.draftRecordId.equals(draftRecordId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAtMillis)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> setRevisionRemoteId(int revisionLocalId, String remoteRevisionId) {
    return (update(amcRecordRevisions)
          ..where((t) => t.revisionLocalId.equals(revisionLocalId)))
        .write(AmcRecordRevisionsCompanion(
            remoteRevisionId: Value(remoteRevisionId)));
  }
}

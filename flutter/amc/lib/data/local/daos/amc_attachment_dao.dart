import 'package:drift/drift.dart';

import '../amc_tables.dart';
import '../database.dart';

part 'amc_attachment_dao.g.dart';

@DriftAccessor(tables: [AmcAttachmentQueue])
class AmcAttachmentDao extends DatabaseAccessor<AppDatabase>
    with _$AmcAttachmentDaoMixin {
  AmcAttachmentDao(super.attachedDatabase);

  Future<int> enqueue(AmcAttachmentQueueCompanion attachment) =>
      into(amcAttachmentQueue).insert(attachment);

  /// アップロード対象（PENDING / NEEDS_RETRY）を取得（AmcAttachmentUploadWorker 用）。
  Future<List<AmcAttachment>> getPendingOnce() {
    return (select(amcAttachmentQueue)
          ..where((t) =>
              t.state.equalsValue(AmcAttachmentState.pending) |
              t.state.equalsValue(AmcAttachmentState.needsRetry)))
        .get();
  }

  /// DB 同期対象（READY かつ storagePath 確定済み）を draft 単位で取得。
  Future<List<AmcAttachment>> getReadyByDraftId(int draftRecordId) {
    return (select(amcAttachmentQueue)
          ..where((t) =>
              t.draftRecordId.equals(draftRecordId) &
              t.state.equalsValue(AmcAttachmentState.ready) &
              t.storagePath.isNotNull()))
        .get();
  }

  /// アップロード開始。attempt 番号を +1 し state=uploading（§4.2）。
  Future<void> markUploading(int attachmentId) async {
    await customUpdate(
      '''
      UPDATE amc_attachment_queue
      SET state = 'uploading', attempt_number = attempt_number + 1
      WHERE attachment_id = ?
      ''',
      variables: [Variable.withInt(attachmentId)],
      updates: {amcAttachmentQueue},
      updateKind: UpdateKind.update,
    );
  }

  Future<void> markReady(int attachmentId, String storagePath) {
    return (update(amcAttachmentQueue)
          ..where((t) => t.attachmentId.equals(attachmentId)))
        .write(AmcAttachmentQueueCompanion(
      state: const Value(AmcAttachmentState.ready),
      storagePath: Value(storagePath),
    ));
  }

  Future<void> markNeedsRetry(int attachmentId, {String? errorCode}) {
    return (update(amcAttachmentQueue)
          ..where((t) => t.attachmentId.equals(attachmentId)))
        .write(AmcAttachmentQueueCompanion(
      state: const Value(AmcAttachmentState.needsRetry),
      lastErrorCode:
          errorCode == null ? const Value.absent() : Value(errorCode),
    ));
  }

  Future<void> markFailed(int attachmentId, {String? errorCode}) {
    return (update(amcAttachmentQueue)
          ..where((t) => t.attachmentId.equals(attachmentId)))
        .write(AmcAttachmentQueueCompanion(
      state: const Value(AmcAttachmentState.failed),
      lastErrorCode:
          errorCode == null ? const Value.absent() : Value(errorCode),
    ));
  }

  Future<void> setRemoteAttachmentId(int attachmentId, String remoteId) {
    return (update(amcAttachmentQueue)
          ..where((t) => t.attachmentId.equals(attachmentId)))
        .write(AmcAttachmentQueueCompanion(remoteAttachmentId: Value(remoteId)));
  }

  Future<void> deleteById(int attachmentId) =>
      (delete(amcAttachmentQueue)..where((t) => t.attachmentId.equals(attachmentId)))
          .go();
}

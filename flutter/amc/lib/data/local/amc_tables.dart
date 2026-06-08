import 'package:drift/drift.dart';

/// AMC クラウド同期キュー用テーブル群（migration_plan.md §3.2）。
///
/// UI 用テーブル（tables.dart）とは別系統で、「サーバー同期の状態機械」を持つ。
/// Android の amc_draft_records / amc_record_revisions / amc_attachment_queue 相当。

/// 下書きのサーバー同期状態。
enum AmcSyncState { draft, queued, synced, failed }

/// 添付の Storage アップロード状態。
enum AmcAttachmentState { pending, uploading, ready, needsRetry, failed, expired }

@DataClassName('AmcDraftRecord')
class AmcDraftRecords extends Table {
  IntColumn get draftRecordId => integer().autoIncrement()();
  IntColumn get obsEventId => integer().nullable()(); // どのイベントの記録か（ソフト参照）
  TextColumn get currentBody => text().withDefault(const Constant(''))();
  TextColumn get visibility => text().withDefault(const Constant('private'))();
  TextColumn get syncState => textEnum<AmcSyncState>()();
  TextColumn get remoteRecordId => text().nullable()(); // Supabase amc_records.id (UUID)
  TextColumn get currentRevisionId => text().nullable()();
  IntColumn get updatedAtMillis => integer()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
}

@DataClassName('AmcRecordRevision')
@TableIndex(name: 'idx_amc_revisions_draft', columns: {#draftRecordId})
class AmcRecordRevisions extends Table {
  IntColumn get revisionLocalId => integer().autoIncrement()();
  IntColumn get draftRecordId => integer()
      .references(AmcDraftRecords, #draftRecordId, onDelete: KeyAction.cascade)();
  TextColumn get body => text()();
  TextColumn get idempotencyKey => text()();
  TextColumn get remoteRevisionId => text().nullable()();
  IntColumn get createdAtMillis => integer()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {idempotencyKey},
      ];
}

@DataClassName('AmcAttachment')
@TableIndex(name: 'idx_amc_attachments_draft', columns: {#draftRecordId})
class AmcAttachmentQueue extends Table {
  IntColumn get attachmentId => integer().autoIncrement()();
  IntColumn get draftRecordId => integer()
      .references(AmcDraftRecords, #draftRecordId, onDelete: KeyAction.cascade)();
  TextColumn get localUri => text()(); // file:// 圧縮済みファイル
  TextColumn get mimeType => text()(); // whitelist: image/jpeg, audio/m4a
  TextColumn get state => textEnum<AmcAttachmentState>()();
  TextColumn get storagePath => text().nullable()(); // {userId}/{draftId}/{attachmentId}.jpg
  TextColumn get remoteAttachmentId => text().nullable()();
  IntColumn get attemptNumber => integer().withDefault(const Constant(0))();
  TextColumn get lastErrorCode => text().nullable()();
  IntColumn get expiresAtMillis => integer().nullable()();
  TextColumn get checksum => text().nullable()();
}

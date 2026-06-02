// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'amc_draft_dao.dart';

// ignore_for_file: type=lint
mixin _$AmcDraftDaoMixin on DatabaseAccessor<AppDatabase> {
  $AmcDraftRecordsTable get amcDraftRecords => attachedDatabase.amcDraftRecords;
  $AmcRecordRevisionsTable get amcRecordRevisions =>
      attachedDatabase.amcRecordRevisions;
  AmcDraftDaoManager get managers => AmcDraftDaoManager(this);
}

class AmcDraftDaoManager {
  final _$AmcDraftDaoMixin _db;
  AmcDraftDaoManager(this._db);
  $$AmcDraftRecordsTableTableManager get amcDraftRecords =>
      $$AmcDraftRecordsTableTableManager(
        _db.attachedDatabase,
        _db.amcDraftRecords,
      );
  $$AmcRecordRevisionsTableTableManager get amcRecordRevisions =>
      $$AmcRecordRevisionsTableTableManager(
        _db.attachedDatabase,
        _db.amcRecordRevisions,
      );
}

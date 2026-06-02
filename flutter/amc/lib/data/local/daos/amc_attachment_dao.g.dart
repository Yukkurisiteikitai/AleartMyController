// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'amc_attachment_dao.dart';

// ignore_for_file: type=lint
mixin _$AmcAttachmentDaoMixin on DatabaseAccessor<AppDatabase> {
  $AmcDraftRecordsTable get amcDraftRecords => attachedDatabase.amcDraftRecords;
  $AmcAttachmentQueueTable get amcAttachmentQueue =>
      attachedDatabase.amcAttachmentQueue;
  AmcAttachmentDaoManager get managers => AmcAttachmentDaoManager(this);
}

class AmcAttachmentDaoManager {
  final _$AmcAttachmentDaoMixin _db;
  AmcAttachmentDaoManager(this._db);
  $$AmcDraftRecordsTableTableManager get amcDraftRecords =>
      $$AmcDraftRecordsTableTableManager(
        _db.attachedDatabase,
        _db.amcDraftRecords,
      );
  $$AmcAttachmentQueueTableTableManager get amcAttachmentQueue =>
      $$AmcAttachmentQueueTableTableManager(
        _db.attachedDatabase,
        _db.amcAttachmentQueue,
      );
}

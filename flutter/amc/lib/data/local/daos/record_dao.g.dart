// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'record_dao.dart';

// ignore_for_file: type=lint
mixin _$RecordDaoMixin on DatabaseAccessor<AppDatabase> {
  $ObservationEventsTable get observationEvents =>
      attachedDatabase.observationEvents;
  $RecordsTable get records => attachedDatabase.records;
  $PhotosTable get photos => attachedDatabase.photos;
  $MemosTable get memos => attachedDatabase.memos;
  $EventsTable get events => attachedDatabase.events;
  RecordDaoManager get managers => RecordDaoManager(this);
}

class RecordDaoManager {
  final _$RecordDaoMixin _db;
  RecordDaoManager(this._db);
  $$ObservationEventsTableTableManager get observationEvents =>
      $$ObservationEventsTableTableManager(
        _db.attachedDatabase,
        _db.observationEvents,
      );
  $$RecordsTableTableManager get records =>
      $$RecordsTableTableManager(_db.attachedDatabase, _db.records);
  $$PhotosTableTableManager get photos =>
      $$PhotosTableTableManager(_db.attachedDatabase, _db.photos);
  $$MemosTableTableManager get memos =>
      $$MemosTableTableManager(_db.attachedDatabase, _db.memos);
  $$EventsTableTableManager get events =>
      $$EventsTableTableManager(_db.attachedDatabase, _db.events);
}

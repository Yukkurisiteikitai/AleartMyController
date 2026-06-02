// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memo_dao.dart';

// ignore_for_file: type=lint
mixin _$MemoDaoMixin on DatabaseAccessor<AppDatabase> {
  $ObservationEventsTable get observationEvents =>
      attachedDatabase.observationEvents;
  $RecordsTable get records => attachedDatabase.records;
  $MemosTable get memos => attachedDatabase.memos;
  MemoDaoManager get managers => MemoDaoManager(this);
}

class MemoDaoManager {
  final _$MemoDaoMixin _db;
  MemoDaoManager(this._db);
  $$ObservationEventsTableTableManager get observationEvents =>
      $$ObservationEventsTableTableManager(
        _db.attachedDatabase,
        _db.observationEvents,
      );
  $$RecordsTableTableManager get records =>
      $$RecordsTableTableManager(_db.attachedDatabase, _db.records);
  $$MemosTableTableManager get memos =>
      $$MemosTableTableManager(_db.attachedDatabase, _db.memos);
}

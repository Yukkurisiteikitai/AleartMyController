// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo_dao.dart';

// ignore_for_file: type=lint
mixin _$PhotoDaoMixin on DatabaseAccessor<AppDatabase> {
  $ObservationEventsTable get observationEvents =>
      attachedDatabase.observationEvents;
  $RecordsTable get records => attachedDatabase.records;
  $PhotosTable get photos => attachedDatabase.photos;
  PhotoDaoManager get managers => PhotoDaoManager(this);
}

class PhotoDaoManager {
  final _$PhotoDaoMixin _db;
  PhotoDaoManager(this._db);
  $$ObservationEventsTableTableManager get observationEvents =>
      $$ObservationEventsTableTableManager(
        _db.attachedDatabase,
        _db.observationEvents,
      );
  $$RecordsTableTableManager get records =>
      $$RecordsTableTableManager(_db.attachedDatabase, _db.records);
  $$PhotosTableTableManager get photos =>
      $$PhotosTableTableManager(_db.attachedDatabase, _db.photos);
}

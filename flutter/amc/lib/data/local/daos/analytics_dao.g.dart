// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_dao.dart';

// ignore_for_file: type=lint
mixin _$AnalyticsDaoMixin on DatabaseAccessor<AppDatabase> {
  $ObservationEventsTable get observationEvents =>
      attachedDatabase.observationEvents;
  $RecordsTable get records => attachedDatabase.records;
  AnalyticsDaoManager get managers => AnalyticsDaoManager(this);
}

class AnalyticsDaoManager {
  final _$AnalyticsDaoMixin _db;
  AnalyticsDaoManager(this._db);
  $$ObservationEventsTableTableManager get observationEvents =>
      $$ObservationEventsTableTableManager(
        _db.attachedDatabase,
        _db.observationEvents,
      );
  $$RecordsTableTableManager get records =>
      $$RecordsTableTableManager(_db.attachedDatabase, _db.records);
}

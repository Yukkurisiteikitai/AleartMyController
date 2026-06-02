// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'observation_event_dao.dart';

// ignore_for_file: type=lint
mixin _$ObservationEventDaoMixin on DatabaseAccessor<AppDatabase> {
  $ObservationEventsTable get observationEvents =>
      attachedDatabase.observationEvents;
  ObservationEventDaoManager get managers => ObservationEventDaoManager(this);
}

class ObservationEventDaoManager {
  final _$ObservationEventDaoMixin _db;
  ObservationEventDaoManager(this._db);
  $$ObservationEventsTableTableManager get observationEvents =>
      $$ObservationEventsTableTableManager(
        _db.attachedDatabase,
        _db.observationEvents,
      );
}

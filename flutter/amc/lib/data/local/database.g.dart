// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $EventsTable extends Events with TableInfo<$EventsTable, Event> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<int> eventId = GeneratedColumn<int>(
    'event_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _googleEventIdMeta = const VerificationMeta(
    'googleEventId',
  );
  @override
  late final GeneratedColumn<String> googleEventId = GeneratedColumn<String>(
    'google_event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<int> startTime = GeneratedColumn<int>(
    'start_time',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<int> endTime = GeneratedColumn<int>(
    'end_time',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    eventId,
    googleEventId,
    title,
    startTime,
    endTime,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'events';
  @override
  VerificationContext validateIntegrity(
    Insertable<Event> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    }
    if (data.containsKey('google_event_id')) {
      context.handle(
        _googleEventIdMeta,
        googleEventId.isAcceptableOrUnknown(
          data['google_event_id']!,
          _googleEventIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_googleEventIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_endTimeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {eventId};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {googleEventId},
  ];
  @override
  Event map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Event(
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}event_id'],
      )!,
      googleEventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}google_event_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_time'],
      )!,
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_time'],
      )!,
    );
  }

  @override
  $EventsTable createAlias(String alias) {
    return $EventsTable(attachedDatabase, alias);
  }
}

class Event extends DataClass implements Insertable<Event> {
  final int eventId;
  final String googleEventId;
  final String title;
  final int startTime;
  final int endTime;
  const Event({
    required this.eventId,
    required this.googleEventId,
    required this.title,
    required this.startTime,
    required this.endTime,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['event_id'] = Variable<int>(eventId);
    map['google_event_id'] = Variable<String>(googleEventId);
    map['title'] = Variable<String>(title);
    map['start_time'] = Variable<int>(startTime);
    map['end_time'] = Variable<int>(endTime);
    return map;
  }

  EventsCompanion toCompanion(bool nullToAbsent) {
    return EventsCompanion(
      eventId: Value(eventId),
      googleEventId: Value(googleEventId),
      title: Value(title),
      startTime: Value(startTime),
      endTime: Value(endTime),
    );
  }

  factory Event.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Event(
      eventId: serializer.fromJson<int>(json['eventId']),
      googleEventId: serializer.fromJson<String>(json['googleEventId']),
      title: serializer.fromJson<String>(json['title']),
      startTime: serializer.fromJson<int>(json['startTime']),
      endTime: serializer.fromJson<int>(json['endTime']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'eventId': serializer.toJson<int>(eventId),
      'googleEventId': serializer.toJson<String>(googleEventId),
      'title': serializer.toJson<String>(title),
      'startTime': serializer.toJson<int>(startTime),
      'endTime': serializer.toJson<int>(endTime),
    };
  }

  Event copyWith({
    int? eventId,
    String? googleEventId,
    String? title,
    int? startTime,
    int? endTime,
  }) => Event(
    eventId: eventId ?? this.eventId,
    googleEventId: googleEventId ?? this.googleEventId,
    title: title ?? this.title,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
  );
  Event copyWithCompanion(EventsCompanion data) {
    return Event(
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      googleEventId: data.googleEventId.present
          ? data.googleEventId.value
          : this.googleEventId,
      title: data.title.present ? data.title.value : this.title,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Event(')
          ..write('eventId: $eventId, ')
          ..write('googleEventId: $googleEventId, ')
          ..write('title: $title, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(eventId, googleEventId, title, startTime, endTime);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Event &&
          other.eventId == this.eventId &&
          other.googleEventId == this.googleEventId &&
          other.title == this.title &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime);
}

class EventsCompanion extends UpdateCompanion<Event> {
  final Value<int> eventId;
  final Value<String> googleEventId;
  final Value<String> title;
  final Value<int> startTime;
  final Value<int> endTime;
  const EventsCompanion({
    this.eventId = const Value.absent(),
    this.googleEventId = const Value.absent(),
    this.title = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
  });
  EventsCompanion.insert({
    this.eventId = const Value.absent(),
    required String googleEventId,
    required String title,
    required int startTime,
    required int endTime,
  }) : googleEventId = Value(googleEventId),
       title = Value(title),
       startTime = Value(startTime),
       endTime = Value(endTime);
  static Insertable<Event> custom({
    Expression<int>? eventId,
    Expression<String>? googleEventId,
    Expression<String>? title,
    Expression<int>? startTime,
    Expression<int>? endTime,
  }) {
    return RawValuesInsertable({
      if (eventId != null) 'event_id': eventId,
      if (googleEventId != null) 'google_event_id': googleEventId,
      if (title != null) 'title': title,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
    });
  }

  EventsCompanion copyWith({
    Value<int>? eventId,
    Value<String>? googleEventId,
    Value<String>? title,
    Value<int>? startTime,
    Value<int>? endTime,
  }) {
    return EventsCompanion(
      eventId: eventId ?? this.eventId,
      googleEventId: googleEventId ?? this.googleEventId,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (eventId.present) {
      map['event_id'] = Variable<int>(eventId.value);
    }
    if (googleEventId.present) {
      map['google_event_id'] = Variable<String>(googleEventId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<int>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<int>(endTime.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventsCompanion(')
          ..write('eventId: $eventId, ')
          ..write('googleEventId: $googleEventId, ')
          ..write('title: $title, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime')
          ..write(')'))
        .toString();
  }
}

class $ObservationEventsTable extends ObservationEvents
    with TableInfo<$ObservationEventsTable, ObservationEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ObservationEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _obsEventIdMeta = const VerificationMeta(
    'obsEventId',
  );
  @override
  late final GeneratedColumn<int> obsEventId = GeneratedColumn<int>(
    'obs_event_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _googleEventIdMeta = const VerificationMeta(
    'googleEventId',
  );
  @override
  late final GeneratedColumn<String> googleEventId = GeneratedColumn<String>(
    'google_event_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<int> startTime = GeneratedColumn<int>(
    'start_time',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<int> endTime = GeneratedColumn<int>(
    'end_time',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    obsEventId,
    googleEventId,
    title,
    startTime,
    endTime,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'observation_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<ObservationEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('obs_event_id')) {
      context.handle(
        _obsEventIdMeta,
        obsEventId.isAcceptableOrUnknown(
          data['obs_event_id']!,
          _obsEventIdMeta,
        ),
      );
    }
    if (data.containsKey('google_event_id')) {
      context.handle(
        _googleEventIdMeta,
        googleEventId.isAcceptableOrUnknown(
          data['google_event_id']!,
          _googleEventIdMeta,
        ),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_endTimeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {obsEventId};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {googleEventId},
  ];
  @override
  ObservationEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ObservationEvent(
      obsEventId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}obs_event_id'],
      )!,
      googleEventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}google_event_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_time'],
      )!,
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_time'],
      )!,
    );
  }

  @override
  $ObservationEventsTable createAlias(String alias) {
    return $ObservationEventsTable(attachedDatabase, alias);
  }
}

class ObservationEvent extends DataClass
    implements Insertable<ObservationEvent> {
  final int obsEventId;
  final String? googleEventId;
  final String title;
  final int startTime;
  final int endTime;
  const ObservationEvent({
    required this.obsEventId,
    this.googleEventId,
    required this.title,
    required this.startTime,
    required this.endTime,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['obs_event_id'] = Variable<int>(obsEventId);
    if (!nullToAbsent || googleEventId != null) {
      map['google_event_id'] = Variable<String>(googleEventId);
    }
    map['title'] = Variable<String>(title);
    map['start_time'] = Variable<int>(startTime);
    map['end_time'] = Variable<int>(endTime);
    return map;
  }

  ObservationEventsCompanion toCompanion(bool nullToAbsent) {
    return ObservationEventsCompanion(
      obsEventId: Value(obsEventId),
      googleEventId: googleEventId == null && nullToAbsent
          ? const Value.absent()
          : Value(googleEventId),
      title: Value(title),
      startTime: Value(startTime),
      endTime: Value(endTime),
    );
  }

  factory ObservationEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ObservationEvent(
      obsEventId: serializer.fromJson<int>(json['obsEventId']),
      googleEventId: serializer.fromJson<String?>(json['googleEventId']),
      title: serializer.fromJson<String>(json['title']),
      startTime: serializer.fromJson<int>(json['startTime']),
      endTime: serializer.fromJson<int>(json['endTime']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'obsEventId': serializer.toJson<int>(obsEventId),
      'googleEventId': serializer.toJson<String?>(googleEventId),
      'title': serializer.toJson<String>(title),
      'startTime': serializer.toJson<int>(startTime),
      'endTime': serializer.toJson<int>(endTime),
    };
  }

  ObservationEvent copyWith({
    int? obsEventId,
    Value<String?> googleEventId = const Value.absent(),
    String? title,
    int? startTime,
    int? endTime,
  }) => ObservationEvent(
    obsEventId: obsEventId ?? this.obsEventId,
    googleEventId: googleEventId.present
        ? googleEventId.value
        : this.googleEventId,
    title: title ?? this.title,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
  );
  ObservationEvent copyWithCompanion(ObservationEventsCompanion data) {
    return ObservationEvent(
      obsEventId: data.obsEventId.present
          ? data.obsEventId.value
          : this.obsEventId,
      googleEventId: data.googleEventId.present
          ? data.googleEventId.value
          : this.googleEventId,
      title: data.title.present ? data.title.value : this.title,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ObservationEvent(')
          ..write('obsEventId: $obsEventId, ')
          ..write('googleEventId: $googleEventId, ')
          ..write('title: $title, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(obsEventId, googleEventId, title, startTime, endTime);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ObservationEvent &&
          other.obsEventId == this.obsEventId &&
          other.googleEventId == this.googleEventId &&
          other.title == this.title &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime);
}

class ObservationEventsCompanion extends UpdateCompanion<ObservationEvent> {
  final Value<int> obsEventId;
  final Value<String?> googleEventId;
  final Value<String> title;
  final Value<int> startTime;
  final Value<int> endTime;
  const ObservationEventsCompanion({
    this.obsEventId = const Value.absent(),
    this.googleEventId = const Value.absent(),
    this.title = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
  });
  ObservationEventsCompanion.insert({
    this.obsEventId = const Value.absent(),
    this.googleEventId = const Value.absent(),
    required String title,
    required int startTime,
    required int endTime,
  }) : title = Value(title),
       startTime = Value(startTime),
       endTime = Value(endTime);
  static Insertable<ObservationEvent> custom({
    Expression<int>? obsEventId,
    Expression<String>? googleEventId,
    Expression<String>? title,
    Expression<int>? startTime,
    Expression<int>? endTime,
  }) {
    return RawValuesInsertable({
      if (obsEventId != null) 'obs_event_id': obsEventId,
      if (googleEventId != null) 'google_event_id': googleEventId,
      if (title != null) 'title': title,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
    });
  }

  ObservationEventsCompanion copyWith({
    Value<int>? obsEventId,
    Value<String?>? googleEventId,
    Value<String>? title,
    Value<int>? startTime,
    Value<int>? endTime,
  }) {
    return ObservationEventsCompanion(
      obsEventId: obsEventId ?? this.obsEventId,
      googleEventId: googleEventId ?? this.googleEventId,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (obsEventId.present) {
      map['obs_event_id'] = Variable<int>(obsEventId.value);
    }
    if (googleEventId.present) {
      map['google_event_id'] = Variable<String>(googleEventId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<int>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<int>(endTime.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ObservationEventsCompanion(')
          ..write('obsEventId: $obsEventId, ')
          ..write('googleEventId: $googleEventId, ')
          ..write('title: $title, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime')
          ..write(')'))
        .toString();
  }
}

class $RecordsTable extends Records with TableInfo<$RecordsTable, Record> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  @override
  late final GeneratedColumn<int> recordId = GeneratedColumn<int>(
    'record_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _obsEventIdMeta = const VerificationMeta(
    'obsEventId',
  );
  @override
  late final GeneratedColumn<int> obsEventId = GeneratedColumn<int>(
    'obs_event_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES observation_events (obs_event_id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _recordTimeMeta = const VerificationMeta(
    'recordTime',
  );
  @override
  late final GeneratedColumn<int> recordTime = GeneratedColumn<int>(
    'record_time',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<RecordType, String> recordType =
      GeneratedColumn<String>(
        'record_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<RecordType>($RecordsTable.$converterrecordType);
  @override
  List<GeneratedColumn> get $columns => [
    recordId,
    obsEventId,
    recordTime,
    recordType,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'records';
  @override
  VerificationContext validateIntegrity(
    Insertable<Record> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    }
    if (data.containsKey('obs_event_id')) {
      context.handle(
        _obsEventIdMeta,
        obsEventId.isAcceptableOrUnknown(
          data['obs_event_id']!,
          _obsEventIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_obsEventIdMeta);
    }
    if (data.containsKey('record_time')) {
      context.handle(
        _recordTimeMeta,
        recordTime.isAcceptableOrUnknown(data['record_time']!, _recordTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_recordTimeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {recordId};
  @override
  Record map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Record(
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}record_id'],
      )!,
      obsEventId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}obs_event_id'],
      )!,
      recordTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}record_time'],
      )!,
      recordType: $RecordsTable.$converterrecordType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}record_type'],
        )!,
      ),
    );
  }

  @override
  $RecordsTable createAlias(String alias) {
    return $RecordsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<RecordType, String, String> $converterrecordType =
      const EnumNameConverter<RecordType>(RecordType.values);
}

class Record extends DataClass implements Insertable<Record> {
  final int recordId;
  final int obsEventId;
  final int recordTime;
  final RecordType recordType;
  const Record({
    required this.recordId,
    required this.obsEventId,
    required this.recordTime,
    required this.recordType,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['record_id'] = Variable<int>(recordId);
    map['obs_event_id'] = Variable<int>(obsEventId);
    map['record_time'] = Variable<int>(recordTime);
    {
      map['record_type'] = Variable<String>(
        $RecordsTable.$converterrecordType.toSql(recordType),
      );
    }
    return map;
  }

  RecordsCompanion toCompanion(bool nullToAbsent) {
    return RecordsCompanion(
      recordId: Value(recordId),
      obsEventId: Value(obsEventId),
      recordTime: Value(recordTime),
      recordType: Value(recordType),
    );
  }

  factory Record.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Record(
      recordId: serializer.fromJson<int>(json['recordId']),
      obsEventId: serializer.fromJson<int>(json['obsEventId']),
      recordTime: serializer.fromJson<int>(json['recordTime']),
      recordType: $RecordsTable.$converterrecordType.fromJson(
        serializer.fromJson<String>(json['recordType']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'recordId': serializer.toJson<int>(recordId),
      'obsEventId': serializer.toJson<int>(obsEventId),
      'recordTime': serializer.toJson<int>(recordTime),
      'recordType': serializer.toJson<String>(
        $RecordsTable.$converterrecordType.toJson(recordType),
      ),
    };
  }

  Record copyWith({
    int? recordId,
    int? obsEventId,
    int? recordTime,
    RecordType? recordType,
  }) => Record(
    recordId: recordId ?? this.recordId,
    obsEventId: obsEventId ?? this.obsEventId,
    recordTime: recordTime ?? this.recordTime,
    recordType: recordType ?? this.recordType,
  );
  Record copyWithCompanion(RecordsCompanion data) {
    return Record(
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      obsEventId: data.obsEventId.present
          ? data.obsEventId.value
          : this.obsEventId,
      recordTime: data.recordTime.present
          ? data.recordTime.value
          : this.recordTime,
      recordType: data.recordType.present
          ? data.recordType.value
          : this.recordType,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Record(')
          ..write('recordId: $recordId, ')
          ..write('obsEventId: $obsEventId, ')
          ..write('recordTime: $recordTime, ')
          ..write('recordType: $recordType')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(recordId, obsEventId, recordTime, recordType);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Record &&
          other.recordId == this.recordId &&
          other.obsEventId == this.obsEventId &&
          other.recordTime == this.recordTime &&
          other.recordType == this.recordType);
}

class RecordsCompanion extends UpdateCompanion<Record> {
  final Value<int> recordId;
  final Value<int> obsEventId;
  final Value<int> recordTime;
  final Value<RecordType> recordType;
  const RecordsCompanion({
    this.recordId = const Value.absent(),
    this.obsEventId = const Value.absent(),
    this.recordTime = const Value.absent(),
    this.recordType = const Value.absent(),
  });
  RecordsCompanion.insert({
    this.recordId = const Value.absent(),
    required int obsEventId,
    required int recordTime,
    required RecordType recordType,
  }) : obsEventId = Value(obsEventId),
       recordTime = Value(recordTime),
       recordType = Value(recordType);
  static Insertable<Record> custom({
    Expression<int>? recordId,
    Expression<int>? obsEventId,
    Expression<int>? recordTime,
    Expression<String>? recordType,
  }) {
    return RawValuesInsertable({
      if (recordId != null) 'record_id': recordId,
      if (obsEventId != null) 'obs_event_id': obsEventId,
      if (recordTime != null) 'record_time': recordTime,
      if (recordType != null) 'record_type': recordType,
    });
  }

  RecordsCompanion copyWith({
    Value<int>? recordId,
    Value<int>? obsEventId,
    Value<int>? recordTime,
    Value<RecordType>? recordType,
  }) {
    return RecordsCompanion(
      recordId: recordId ?? this.recordId,
      obsEventId: obsEventId ?? this.obsEventId,
      recordTime: recordTime ?? this.recordTime,
      recordType: recordType ?? this.recordType,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (recordId.present) {
      map['record_id'] = Variable<int>(recordId.value);
    }
    if (obsEventId.present) {
      map['obs_event_id'] = Variable<int>(obsEventId.value);
    }
    if (recordTime.present) {
      map['record_time'] = Variable<int>(recordTime.value);
    }
    if (recordType.present) {
      map['record_type'] = Variable<String>(
        $RecordsTable.$converterrecordType.toSql(recordType.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecordsCompanion(')
          ..write('recordId: $recordId, ')
          ..write('obsEventId: $obsEventId, ')
          ..write('recordTime: $recordTime, ')
          ..write('recordType: $recordType')
          ..write(')'))
        .toString();
  }
}

class $PhotosTable extends Photos with TableInfo<$PhotosTable, Photo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PhotosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _photoIdMeta = const VerificationMeta(
    'photoId',
  );
  @override
  late final GeneratedColumn<int> photoId = GeneratedColumn<int>(
    'photo_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  @override
  late final GeneratedColumn<int> recordId = GeneratedColumn<int>(
    'record_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES records (record_id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [photoId, recordId, filePath];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'photos';
  @override
  VerificationContext validateIntegrity(
    Insertable<Photo> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('photo_id')) {
      context.handle(
        _photoIdMeta,
        photoId.isAcceptableOrUnknown(data['photo_id']!, _photoIdMeta),
      );
    }
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {photoId};
  @override
  Photo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Photo(
      photoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}photo_id'],
      )!,
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}record_id'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
    );
  }

  @override
  $PhotosTable createAlias(String alias) {
    return $PhotosTable(attachedDatabase, alias);
  }
}

class Photo extends DataClass implements Insertable<Photo> {
  final int photoId;
  final int recordId;
  final String filePath;
  const Photo({
    required this.photoId,
    required this.recordId,
    required this.filePath,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['photo_id'] = Variable<int>(photoId);
    map['record_id'] = Variable<int>(recordId);
    map['file_path'] = Variable<String>(filePath);
    return map;
  }

  PhotosCompanion toCompanion(bool nullToAbsent) {
    return PhotosCompanion(
      photoId: Value(photoId),
      recordId: Value(recordId),
      filePath: Value(filePath),
    );
  }

  factory Photo.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Photo(
      photoId: serializer.fromJson<int>(json['photoId']),
      recordId: serializer.fromJson<int>(json['recordId']),
      filePath: serializer.fromJson<String>(json['filePath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'photoId': serializer.toJson<int>(photoId),
      'recordId': serializer.toJson<int>(recordId),
      'filePath': serializer.toJson<String>(filePath),
    };
  }

  Photo copyWith({int? photoId, int? recordId, String? filePath}) => Photo(
    photoId: photoId ?? this.photoId,
    recordId: recordId ?? this.recordId,
    filePath: filePath ?? this.filePath,
  );
  Photo copyWithCompanion(PhotosCompanion data) {
    return Photo(
      photoId: data.photoId.present ? data.photoId.value : this.photoId,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Photo(')
          ..write('photoId: $photoId, ')
          ..write('recordId: $recordId, ')
          ..write('filePath: $filePath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(photoId, recordId, filePath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Photo &&
          other.photoId == this.photoId &&
          other.recordId == this.recordId &&
          other.filePath == this.filePath);
}

class PhotosCompanion extends UpdateCompanion<Photo> {
  final Value<int> photoId;
  final Value<int> recordId;
  final Value<String> filePath;
  const PhotosCompanion({
    this.photoId = const Value.absent(),
    this.recordId = const Value.absent(),
    this.filePath = const Value.absent(),
  });
  PhotosCompanion.insert({
    this.photoId = const Value.absent(),
    required int recordId,
    required String filePath,
  }) : recordId = Value(recordId),
       filePath = Value(filePath);
  static Insertable<Photo> custom({
    Expression<int>? photoId,
    Expression<int>? recordId,
    Expression<String>? filePath,
  }) {
    return RawValuesInsertable({
      if (photoId != null) 'photo_id': photoId,
      if (recordId != null) 'record_id': recordId,
      if (filePath != null) 'file_path': filePath,
    });
  }

  PhotosCompanion copyWith({
    Value<int>? photoId,
    Value<int>? recordId,
    Value<String>? filePath,
  }) {
    return PhotosCompanion(
      photoId: photoId ?? this.photoId,
      recordId: recordId ?? this.recordId,
      filePath: filePath ?? this.filePath,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (photoId.present) {
      map['photo_id'] = Variable<int>(photoId.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<int>(recordId.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PhotosCompanion(')
          ..write('photoId: $photoId, ')
          ..write('recordId: $recordId, ')
          ..write('filePath: $filePath')
          ..write(')'))
        .toString();
  }
}

class $MemosTable extends Memos with TableInfo<$MemosTable, Memo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MemosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _memoIdMeta = const VerificationMeta('memoId');
  @override
  late final GeneratedColumn<int> memoId = GeneratedColumn<int>(
    'memo_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  @override
  late final GeneratedColumn<int> recordId = GeneratedColumn<int>(
    'record_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES records (record_id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _memoTextMeta = const VerificationMeta(
    'memoText',
  );
  @override
  late final GeneratedColumn<String> memoText = GeneratedColumn<String>(
    'memo_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isVoiceMemoMeta = const VerificationMeta(
    'isVoiceMemo',
  );
  @override
  late final GeneratedColumn<bool> isVoiceMemo = GeneratedColumn<bool>(
    'is_voice_memo',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_voice_memo" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    memoId,
    recordId,
    memoText,
    isVoiceMemo,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'memos';
  @override
  VerificationContext validateIntegrity(
    Insertable<Memo> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('memo_id')) {
      context.handle(
        _memoIdMeta,
        memoId.isAcceptableOrUnknown(data['memo_id']!, _memoIdMeta),
      );
    }
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('memo_text')) {
      context.handle(
        _memoTextMeta,
        memoText.isAcceptableOrUnknown(data['memo_text']!, _memoTextMeta),
      );
    } else if (isInserting) {
      context.missing(_memoTextMeta);
    }
    if (data.containsKey('is_voice_memo')) {
      context.handle(
        _isVoiceMemoMeta,
        isVoiceMemo.isAcceptableOrUnknown(
          data['is_voice_memo']!,
          _isVoiceMemoMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {memoId};
  @override
  Memo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Memo(
      memoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}memo_id'],
      )!,
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}record_id'],
      )!,
      memoText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memo_text'],
      )!,
      isVoiceMemo: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_voice_memo'],
      )!,
    );
  }

  @override
  $MemosTable createAlias(String alias) {
    return $MemosTable(attachedDatabase, alias);
  }
}

class Memo extends DataClass implements Insertable<Memo> {
  final int memoId;
  final int recordId;
  final String memoText;
  final bool isVoiceMemo;
  const Memo({
    required this.memoId,
    required this.recordId,
    required this.memoText,
    required this.isVoiceMemo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['memo_id'] = Variable<int>(memoId);
    map['record_id'] = Variable<int>(recordId);
    map['memo_text'] = Variable<String>(memoText);
    map['is_voice_memo'] = Variable<bool>(isVoiceMemo);
    return map;
  }

  MemosCompanion toCompanion(bool nullToAbsent) {
    return MemosCompanion(
      memoId: Value(memoId),
      recordId: Value(recordId),
      memoText: Value(memoText),
      isVoiceMemo: Value(isVoiceMemo),
    );
  }

  factory Memo.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Memo(
      memoId: serializer.fromJson<int>(json['memoId']),
      recordId: serializer.fromJson<int>(json['recordId']),
      memoText: serializer.fromJson<String>(json['memoText']),
      isVoiceMemo: serializer.fromJson<bool>(json['isVoiceMemo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'memoId': serializer.toJson<int>(memoId),
      'recordId': serializer.toJson<int>(recordId),
      'memoText': serializer.toJson<String>(memoText),
      'isVoiceMemo': serializer.toJson<bool>(isVoiceMemo),
    };
  }

  Memo copyWith({
    int? memoId,
    int? recordId,
    String? memoText,
    bool? isVoiceMemo,
  }) => Memo(
    memoId: memoId ?? this.memoId,
    recordId: recordId ?? this.recordId,
    memoText: memoText ?? this.memoText,
    isVoiceMemo: isVoiceMemo ?? this.isVoiceMemo,
  );
  Memo copyWithCompanion(MemosCompanion data) {
    return Memo(
      memoId: data.memoId.present ? data.memoId.value : this.memoId,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      memoText: data.memoText.present ? data.memoText.value : this.memoText,
      isVoiceMemo: data.isVoiceMemo.present
          ? data.isVoiceMemo.value
          : this.isVoiceMemo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Memo(')
          ..write('memoId: $memoId, ')
          ..write('recordId: $recordId, ')
          ..write('memoText: $memoText, ')
          ..write('isVoiceMemo: $isVoiceMemo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(memoId, recordId, memoText, isVoiceMemo);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Memo &&
          other.memoId == this.memoId &&
          other.recordId == this.recordId &&
          other.memoText == this.memoText &&
          other.isVoiceMemo == this.isVoiceMemo);
}

class MemosCompanion extends UpdateCompanion<Memo> {
  final Value<int> memoId;
  final Value<int> recordId;
  final Value<String> memoText;
  final Value<bool> isVoiceMemo;
  const MemosCompanion({
    this.memoId = const Value.absent(),
    this.recordId = const Value.absent(),
    this.memoText = const Value.absent(),
    this.isVoiceMemo = const Value.absent(),
  });
  MemosCompanion.insert({
    this.memoId = const Value.absent(),
    required int recordId,
    required String memoText,
    this.isVoiceMemo = const Value.absent(),
  }) : recordId = Value(recordId),
       memoText = Value(memoText);
  static Insertable<Memo> custom({
    Expression<int>? memoId,
    Expression<int>? recordId,
    Expression<String>? memoText,
    Expression<bool>? isVoiceMemo,
  }) {
    return RawValuesInsertable({
      if (memoId != null) 'memo_id': memoId,
      if (recordId != null) 'record_id': recordId,
      if (memoText != null) 'memo_text': memoText,
      if (isVoiceMemo != null) 'is_voice_memo': isVoiceMemo,
    });
  }

  MemosCompanion copyWith({
    Value<int>? memoId,
    Value<int>? recordId,
    Value<String>? memoText,
    Value<bool>? isVoiceMemo,
  }) {
    return MemosCompanion(
      memoId: memoId ?? this.memoId,
      recordId: recordId ?? this.recordId,
      memoText: memoText ?? this.memoText,
      isVoiceMemo: isVoiceMemo ?? this.isVoiceMemo,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (memoId.present) {
      map['memo_id'] = Variable<int>(memoId.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<int>(recordId.value);
    }
    if (memoText.present) {
      map['memo_text'] = Variable<String>(memoText.value);
    }
    if (isVoiceMemo.present) {
      map['is_voice_memo'] = Variable<bool>(isVoiceMemo.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MemosCompanion(')
          ..write('memoId: $memoId, ')
          ..write('recordId: $recordId, ')
          ..write('memoText: $memoText, ')
          ..write('isVoiceMemo: $isVoiceMemo')
          ..write(')'))
        .toString();
  }
}

class $AmcDraftRecordsTable extends AmcDraftRecords
    with TableInfo<$AmcDraftRecordsTable, AmcDraftRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AmcDraftRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _draftRecordIdMeta = const VerificationMeta(
    'draftRecordId',
  );
  @override
  late final GeneratedColumn<int> draftRecordId = GeneratedColumn<int>(
    'draft_record_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _obsEventIdMeta = const VerificationMeta(
    'obsEventId',
  );
  @override
  late final GeneratedColumn<int> obsEventId = GeneratedColumn<int>(
    'obs_event_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currentBodyMeta = const VerificationMeta(
    'currentBody',
  );
  @override
  late final GeneratedColumn<String> currentBody = GeneratedColumn<String>(
    'current_body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _visibilityMeta = const VerificationMeta(
    'visibility',
  );
  @override
  late final GeneratedColumn<String> visibility = GeneratedColumn<String>(
    'visibility',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('private'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<AmcSyncState, String> syncState =
      GeneratedColumn<String>(
        'sync_state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<AmcSyncState>($AmcDraftRecordsTable.$convertersyncState);
  static const VerificationMeta _remoteRecordIdMeta = const VerificationMeta(
    'remoteRecordId',
  );
  @override
  late final GeneratedColumn<String> remoteRecordId = GeneratedColumn<String>(
    'remote_record_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currentRevisionIdMeta = const VerificationMeta(
    'currentRevisionId',
  );
  @override
  late final GeneratedColumn<String> currentRevisionId =
      GeneratedColumn<String>(
        'current_revision_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _updatedAtMillisMeta = const VerificationMeta(
    'updatedAtMillis',
  );
  @override
  late final GeneratedColumn<int> updatedAtMillis = GeneratedColumn<int>(
    'updated_at_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    draftRecordId,
    obsEventId,
    currentBody,
    visibility,
    syncState,
    remoteRecordId,
    currentRevisionId,
    updatedAtMillis,
    deleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'amc_draft_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<AmcDraftRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('draft_record_id')) {
      context.handle(
        _draftRecordIdMeta,
        draftRecordId.isAcceptableOrUnknown(
          data['draft_record_id']!,
          _draftRecordIdMeta,
        ),
      );
    }
    if (data.containsKey('obs_event_id')) {
      context.handle(
        _obsEventIdMeta,
        obsEventId.isAcceptableOrUnknown(
          data['obs_event_id']!,
          _obsEventIdMeta,
        ),
      );
    }
    if (data.containsKey('current_body')) {
      context.handle(
        _currentBodyMeta,
        currentBody.isAcceptableOrUnknown(
          data['current_body']!,
          _currentBodyMeta,
        ),
      );
    }
    if (data.containsKey('visibility')) {
      context.handle(
        _visibilityMeta,
        visibility.isAcceptableOrUnknown(data['visibility']!, _visibilityMeta),
      );
    }
    if (data.containsKey('remote_record_id')) {
      context.handle(
        _remoteRecordIdMeta,
        remoteRecordId.isAcceptableOrUnknown(
          data['remote_record_id']!,
          _remoteRecordIdMeta,
        ),
      );
    }
    if (data.containsKey('current_revision_id')) {
      context.handle(
        _currentRevisionIdMeta,
        currentRevisionId.isAcceptableOrUnknown(
          data['current_revision_id']!,
          _currentRevisionIdMeta,
        ),
      );
    }
    if (data.containsKey('updated_at_millis')) {
      context.handle(
        _updatedAtMillisMeta,
        updatedAtMillis.isAcceptableOrUnknown(
          data['updated_at_millis']!,
          _updatedAtMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMillisMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {draftRecordId};
  @override
  AmcDraftRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AmcDraftRecord(
      draftRecordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}draft_record_id'],
      )!,
      obsEventId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}obs_event_id'],
      ),
      currentBody: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}current_body'],
      )!,
      visibility: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visibility'],
      )!,
      syncState: $AmcDraftRecordsTable.$convertersyncState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_state'],
        )!,
      ),
      remoteRecordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_record_id'],
      ),
      currentRevisionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}current_revision_id'],
      ),
      updatedAtMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_millis'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
    );
  }

  @override
  $AmcDraftRecordsTable createAlias(String alias) {
    return $AmcDraftRecordsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AmcSyncState, String, String> $convertersyncState =
      const EnumNameConverter<AmcSyncState>(AmcSyncState.values);
}

class AmcDraftRecord extends DataClass implements Insertable<AmcDraftRecord> {
  final int draftRecordId;
  final int? obsEventId;
  final String currentBody;
  final String visibility;
  final AmcSyncState syncState;
  final String? remoteRecordId;
  final String? currentRevisionId;
  final int updatedAtMillis;
  final bool deleted;
  const AmcDraftRecord({
    required this.draftRecordId,
    this.obsEventId,
    required this.currentBody,
    required this.visibility,
    required this.syncState,
    this.remoteRecordId,
    this.currentRevisionId,
    required this.updatedAtMillis,
    required this.deleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['draft_record_id'] = Variable<int>(draftRecordId);
    if (!nullToAbsent || obsEventId != null) {
      map['obs_event_id'] = Variable<int>(obsEventId);
    }
    map['current_body'] = Variable<String>(currentBody);
    map['visibility'] = Variable<String>(visibility);
    {
      map['sync_state'] = Variable<String>(
        $AmcDraftRecordsTable.$convertersyncState.toSql(syncState),
      );
    }
    if (!nullToAbsent || remoteRecordId != null) {
      map['remote_record_id'] = Variable<String>(remoteRecordId);
    }
    if (!nullToAbsent || currentRevisionId != null) {
      map['current_revision_id'] = Variable<String>(currentRevisionId);
    }
    map['updated_at_millis'] = Variable<int>(updatedAtMillis);
    map['deleted'] = Variable<bool>(deleted);
    return map;
  }

  AmcDraftRecordsCompanion toCompanion(bool nullToAbsent) {
    return AmcDraftRecordsCompanion(
      draftRecordId: Value(draftRecordId),
      obsEventId: obsEventId == null && nullToAbsent
          ? const Value.absent()
          : Value(obsEventId),
      currentBody: Value(currentBody),
      visibility: Value(visibility),
      syncState: Value(syncState),
      remoteRecordId: remoteRecordId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteRecordId),
      currentRevisionId: currentRevisionId == null && nullToAbsent
          ? const Value.absent()
          : Value(currentRevisionId),
      updatedAtMillis: Value(updatedAtMillis),
      deleted: Value(deleted),
    );
  }

  factory AmcDraftRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AmcDraftRecord(
      draftRecordId: serializer.fromJson<int>(json['draftRecordId']),
      obsEventId: serializer.fromJson<int?>(json['obsEventId']),
      currentBody: serializer.fromJson<String>(json['currentBody']),
      visibility: serializer.fromJson<String>(json['visibility']),
      syncState: $AmcDraftRecordsTable.$convertersyncState.fromJson(
        serializer.fromJson<String>(json['syncState']),
      ),
      remoteRecordId: serializer.fromJson<String?>(json['remoteRecordId']),
      currentRevisionId: serializer.fromJson<String?>(
        json['currentRevisionId'],
      ),
      updatedAtMillis: serializer.fromJson<int>(json['updatedAtMillis']),
      deleted: serializer.fromJson<bool>(json['deleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'draftRecordId': serializer.toJson<int>(draftRecordId),
      'obsEventId': serializer.toJson<int?>(obsEventId),
      'currentBody': serializer.toJson<String>(currentBody),
      'visibility': serializer.toJson<String>(visibility),
      'syncState': serializer.toJson<String>(
        $AmcDraftRecordsTable.$convertersyncState.toJson(syncState),
      ),
      'remoteRecordId': serializer.toJson<String?>(remoteRecordId),
      'currentRevisionId': serializer.toJson<String?>(currentRevisionId),
      'updatedAtMillis': serializer.toJson<int>(updatedAtMillis),
      'deleted': serializer.toJson<bool>(deleted),
    };
  }

  AmcDraftRecord copyWith({
    int? draftRecordId,
    Value<int?> obsEventId = const Value.absent(),
    String? currentBody,
    String? visibility,
    AmcSyncState? syncState,
    Value<String?> remoteRecordId = const Value.absent(),
    Value<String?> currentRevisionId = const Value.absent(),
    int? updatedAtMillis,
    bool? deleted,
  }) => AmcDraftRecord(
    draftRecordId: draftRecordId ?? this.draftRecordId,
    obsEventId: obsEventId.present ? obsEventId.value : this.obsEventId,
    currentBody: currentBody ?? this.currentBody,
    visibility: visibility ?? this.visibility,
    syncState: syncState ?? this.syncState,
    remoteRecordId: remoteRecordId.present
        ? remoteRecordId.value
        : this.remoteRecordId,
    currentRevisionId: currentRevisionId.present
        ? currentRevisionId.value
        : this.currentRevisionId,
    updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
    deleted: deleted ?? this.deleted,
  );
  AmcDraftRecord copyWithCompanion(AmcDraftRecordsCompanion data) {
    return AmcDraftRecord(
      draftRecordId: data.draftRecordId.present
          ? data.draftRecordId.value
          : this.draftRecordId,
      obsEventId: data.obsEventId.present
          ? data.obsEventId.value
          : this.obsEventId,
      currentBody: data.currentBody.present
          ? data.currentBody.value
          : this.currentBody,
      visibility: data.visibility.present
          ? data.visibility.value
          : this.visibility,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      remoteRecordId: data.remoteRecordId.present
          ? data.remoteRecordId.value
          : this.remoteRecordId,
      currentRevisionId: data.currentRevisionId.present
          ? data.currentRevisionId.value
          : this.currentRevisionId,
      updatedAtMillis: data.updatedAtMillis.present
          ? data.updatedAtMillis.value
          : this.updatedAtMillis,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AmcDraftRecord(')
          ..write('draftRecordId: $draftRecordId, ')
          ..write('obsEventId: $obsEventId, ')
          ..write('currentBody: $currentBody, ')
          ..write('visibility: $visibility, ')
          ..write('syncState: $syncState, ')
          ..write('remoteRecordId: $remoteRecordId, ')
          ..write('currentRevisionId: $currentRevisionId, ')
          ..write('updatedAtMillis: $updatedAtMillis, ')
          ..write('deleted: $deleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    draftRecordId,
    obsEventId,
    currentBody,
    visibility,
    syncState,
    remoteRecordId,
    currentRevisionId,
    updatedAtMillis,
    deleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AmcDraftRecord &&
          other.draftRecordId == this.draftRecordId &&
          other.obsEventId == this.obsEventId &&
          other.currentBody == this.currentBody &&
          other.visibility == this.visibility &&
          other.syncState == this.syncState &&
          other.remoteRecordId == this.remoteRecordId &&
          other.currentRevisionId == this.currentRevisionId &&
          other.updatedAtMillis == this.updatedAtMillis &&
          other.deleted == this.deleted);
}

class AmcDraftRecordsCompanion extends UpdateCompanion<AmcDraftRecord> {
  final Value<int> draftRecordId;
  final Value<int?> obsEventId;
  final Value<String> currentBody;
  final Value<String> visibility;
  final Value<AmcSyncState> syncState;
  final Value<String?> remoteRecordId;
  final Value<String?> currentRevisionId;
  final Value<int> updatedAtMillis;
  final Value<bool> deleted;
  const AmcDraftRecordsCompanion({
    this.draftRecordId = const Value.absent(),
    this.obsEventId = const Value.absent(),
    this.currentBody = const Value.absent(),
    this.visibility = const Value.absent(),
    this.syncState = const Value.absent(),
    this.remoteRecordId = const Value.absent(),
    this.currentRevisionId = const Value.absent(),
    this.updatedAtMillis = const Value.absent(),
    this.deleted = const Value.absent(),
  });
  AmcDraftRecordsCompanion.insert({
    this.draftRecordId = const Value.absent(),
    this.obsEventId = const Value.absent(),
    this.currentBody = const Value.absent(),
    this.visibility = const Value.absent(),
    required AmcSyncState syncState,
    this.remoteRecordId = const Value.absent(),
    this.currentRevisionId = const Value.absent(),
    required int updatedAtMillis,
    this.deleted = const Value.absent(),
  }) : syncState = Value(syncState),
       updatedAtMillis = Value(updatedAtMillis);
  static Insertable<AmcDraftRecord> custom({
    Expression<int>? draftRecordId,
    Expression<int>? obsEventId,
    Expression<String>? currentBody,
    Expression<String>? visibility,
    Expression<String>? syncState,
    Expression<String>? remoteRecordId,
    Expression<String>? currentRevisionId,
    Expression<int>? updatedAtMillis,
    Expression<bool>? deleted,
  }) {
    return RawValuesInsertable({
      if (draftRecordId != null) 'draft_record_id': draftRecordId,
      if (obsEventId != null) 'obs_event_id': obsEventId,
      if (currentBody != null) 'current_body': currentBody,
      if (visibility != null) 'visibility': visibility,
      if (syncState != null) 'sync_state': syncState,
      if (remoteRecordId != null) 'remote_record_id': remoteRecordId,
      if (currentRevisionId != null) 'current_revision_id': currentRevisionId,
      if (updatedAtMillis != null) 'updated_at_millis': updatedAtMillis,
      if (deleted != null) 'deleted': deleted,
    });
  }

  AmcDraftRecordsCompanion copyWith({
    Value<int>? draftRecordId,
    Value<int?>? obsEventId,
    Value<String>? currentBody,
    Value<String>? visibility,
    Value<AmcSyncState>? syncState,
    Value<String?>? remoteRecordId,
    Value<String?>? currentRevisionId,
    Value<int>? updatedAtMillis,
    Value<bool>? deleted,
  }) {
    return AmcDraftRecordsCompanion(
      draftRecordId: draftRecordId ?? this.draftRecordId,
      obsEventId: obsEventId ?? this.obsEventId,
      currentBody: currentBody ?? this.currentBody,
      visibility: visibility ?? this.visibility,
      syncState: syncState ?? this.syncState,
      remoteRecordId: remoteRecordId ?? this.remoteRecordId,
      currentRevisionId: currentRevisionId ?? this.currentRevisionId,
      updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
      deleted: deleted ?? this.deleted,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (draftRecordId.present) {
      map['draft_record_id'] = Variable<int>(draftRecordId.value);
    }
    if (obsEventId.present) {
      map['obs_event_id'] = Variable<int>(obsEventId.value);
    }
    if (currentBody.present) {
      map['current_body'] = Variable<String>(currentBody.value);
    }
    if (visibility.present) {
      map['visibility'] = Variable<String>(visibility.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(
        $AmcDraftRecordsTable.$convertersyncState.toSql(syncState.value),
      );
    }
    if (remoteRecordId.present) {
      map['remote_record_id'] = Variable<String>(remoteRecordId.value);
    }
    if (currentRevisionId.present) {
      map['current_revision_id'] = Variable<String>(currentRevisionId.value);
    }
    if (updatedAtMillis.present) {
      map['updated_at_millis'] = Variable<int>(updatedAtMillis.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AmcDraftRecordsCompanion(')
          ..write('draftRecordId: $draftRecordId, ')
          ..write('obsEventId: $obsEventId, ')
          ..write('currentBody: $currentBody, ')
          ..write('visibility: $visibility, ')
          ..write('syncState: $syncState, ')
          ..write('remoteRecordId: $remoteRecordId, ')
          ..write('currentRevisionId: $currentRevisionId, ')
          ..write('updatedAtMillis: $updatedAtMillis, ')
          ..write('deleted: $deleted')
          ..write(')'))
        .toString();
  }
}

class $AmcRecordRevisionsTable extends AmcRecordRevisions
    with TableInfo<$AmcRecordRevisionsTable, AmcRecordRevision> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AmcRecordRevisionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _revisionLocalIdMeta = const VerificationMeta(
    'revisionLocalId',
  );
  @override
  late final GeneratedColumn<int> revisionLocalId = GeneratedColumn<int>(
    'revision_local_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _draftRecordIdMeta = const VerificationMeta(
    'draftRecordId',
  );
  @override
  late final GeneratedColumn<int> draftRecordId = GeneratedColumn<int>(
    'draft_record_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES amc_draft_records (draft_record_id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteRevisionIdMeta = const VerificationMeta(
    'remoteRevisionId',
  );
  @override
  late final GeneratedColumn<String> remoteRevisionId = GeneratedColumn<String>(
    'remote_revision_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMillisMeta = const VerificationMeta(
    'createdAtMillis',
  );
  @override
  late final GeneratedColumn<int> createdAtMillis = GeneratedColumn<int>(
    'created_at_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    revisionLocalId,
    draftRecordId,
    body,
    idempotencyKey,
    remoteRevisionId,
    createdAtMillis,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'amc_record_revisions';
  @override
  VerificationContext validateIntegrity(
    Insertable<AmcRecordRevision> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('revision_local_id')) {
      context.handle(
        _revisionLocalIdMeta,
        revisionLocalId.isAcceptableOrUnknown(
          data['revision_local_id']!,
          _revisionLocalIdMeta,
        ),
      );
    }
    if (data.containsKey('draft_record_id')) {
      context.handle(
        _draftRecordIdMeta,
        draftRecordId.isAcceptableOrUnknown(
          data['draft_record_id']!,
          _draftRecordIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_draftRecordIdMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('remote_revision_id')) {
      context.handle(
        _remoteRevisionIdMeta,
        remoteRevisionId.isAcceptableOrUnknown(
          data['remote_revision_id']!,
          _remoteRevisionIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at_millis')) {
      context.handle(
        _createdAtMillisMeta,
        createdAtMillis.isAcceptableOrUnknown(
          data['created_at_millis']!,
          _createdAtMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMillisMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {revisionLocalId};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {idempotencyKey},
  ];
  @override
  AmcRecordRevision map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AmcRecordRevision(
      revisionLocalId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision_local_id'],
      )!,
      draftRecordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}draft_record_id'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      )!,
      remoteRevisionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_revision_id'],
      ),
      createdAtMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_millis'],
      )!,
    );
  }

  @override
  $AmcRecordRevisionsTable createAlias(String alias) {
    return $AmcRecordRevisionsTable(attachedDatabase, alias);
  }
}

class AmcRecordRevision extends DataClass
    implements Insertable<AmcRecordRevision> {
  final int revisionLocalId;
  final int draftRecordId;
  final String body;
  final String idempotencyKey;
  final String? remoteRevisionId;
  final int createdAtMillis;
  const AmcRecordRevision({
    required this.revisionLocalId,
    required this.draftRecordId,
    required this.body,
    required this.idempotencyKey,
    this.remoteRevisionId,
    required this.createdAtMillis,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['revision_local_id'] = Variable<int>(revisionLocalId);
    map['draft_record_id'] = Variable<int>(draftRecordId);
    map['body'] = Variable<String>(body);
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    if (!nullToAbsent || remoteRevisionId != null) {
      map['remote_revision_id'] = Variable<String>(remoteRevisionId);
    }
    map['created_at_millis'] = Variable<int>(createdAtMillis);
    return map;
  }

  AmcRecordRevisionsCompanion toCompanion(bool nullToAbsent) {
    return AmcRecordRevisionsCompanion(
      revisionLocalId: Value(revisionLocalId),
      draftRecordId: Value(draftRecordId),
      body: Value(body),
      idempotencyKey: Value(idempotencyKey),
      remoteRevisionId: remoteRevisionId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteRevisionId),
      createdAtMillis: Value(createdAtMillis),
    );
  }

  factory AmcRecordRevision.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AmcRecordRevision(
      revisionLocalId: serializer.fromJson<int>(json['revisionLocalId']),
      draftRecordId: serializer.fromJson<int>(json['draftRecordId']),
      body: serializer.fromJson<String>(json['body']),
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      remoteRevisionId: serializer.fromJson<String?>(json['remoteRevisionId']),
      createdAtMillis: serializer.fromJson<int>(json['createdAtMillis']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'revisionLocalId': serializer.toJson<int>(revisionLocalId),
      'draftRecordId': serializer.toJson<int>(draftRecordId),
      'body': serializer.toJson<String>(body),
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'remoteRevisionId': serializer.toJson<String?>(remoteRevisionId),
      'createdAtMillis': serializer.toJson<int>(createdAtMillis),
    };
  }

  AmcRecordRevision copyWith({
    int? revisionLocalId,
    int? draftRecordId,
    String? body,
    String? idempotencyKey,
    Value<String?> remoteRevisionId = const Value.absent(),
    int? createdAtMillis,
  }) => AmcRecordRevision(
    revisionLocalId: revisionLocalId ?? this.revisionLocalId,
    draftRecordId: draftRecordId ?? this.draftRecordId,
    body: body ?? this.body,
    idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    remoteRevisionId: remoteRevisionId.present
        ? remoteRevisionId.value
        : this.remoteRevisionId,
    createdAtMillis: createdAtMillis ?? this.createdAtMillis,
  );
  AmcRecordRevision copyWithCompanion(AmcRecordRevisionsCompanion data) {
    return AmcRecordRevision(
      revisionLocalId: data.revisionLocalId.present
          ? data.revisionLocalId.value
          : this.revisionLocalId,
      draftRecordId: data.draftRecordId.present
          ? data.draftRecordId.value
          : this.draftRecordId,
      body: data.body.present ? data.body.value : this.body,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      remoteRevisionId: data.remoteRevisionId.present
          ? data.remoteRevisionId.value
          : this.remoteRevisionId,
      createdAtMillis: data.createdAtMillis.present
          ? data.createdAtMillis.value
          : this.createdAtMillis,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AmcRecordRevision(')
          ..write('revisionLocalId: $revisionLocalId, ')
          ..write('draftRecordId: $draftRecordId, ')
          ..write('body: $body, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('remoteRevisionId: $remoteRevisionId, ')
          ..write('createdAtMillis: $createdAtMillis')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    revisionLocalId,
    draftRecordId,
    body,
    idempotencyKey,
    remoteRevisionId,
    createdAtMillis,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AmcRecordRevision &&
          other.revisionLocalId == this.revisionLocalId &&
          other.draftRecordId == this.draftRecordId &&
          other.body == this.body &&
          other.idempotencyKey == this.idempotencyKey &&
          other.remoteRevisionId == this.remoteRevisionId &&
          other.createdAtMillis == this.createdAtMillis);
}

class AmcRecordRevisionsCompanion extends UpdateCompanion<AmcRecordRevision> {
  final Value<int> revisionLocalId;
  final Value<int> draftRecordId;
  final Value<String> body;
  final Value<String> idempotencyKey;
  final Value<String?> remoteRevisionId;
  final Value<int> createdAtMillis;
  const AmcRecordRevisionsCompanion({
    this.revisionLocalId = const Value.absent(),
    this.draftRecordId = const Value.absent(),
    this.body = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.remoteRevisionId = const Value.absent(),
    this.createdAtMillis = const Value.absent(),
  });
  AmcRecordRevisionsCompanion.insert({
    this.revisionLocalId = const Value.absent(),
    required int draftRecordId,
    required String body,
    required String idempotencyKey,
    this.remoteRevisionId = const Value.absent(),
    required int createdAtMillis,
  }) : draftRecordId = Value(draftRecordId),
       body = Value(body),
       idempotencyKey = Value(idempotencyKey),
       createdAtMillis = Value(createdAtMillis);
  static Insertable<AmcRecordRevision> custom({
    Expression<int>? revisionLocalId,
    Expression<int>? draftRecordId,
    Expression<String>? body,
    Expression<String>? idempotencyKey,
    Expression<String>? remoteRevisionId,
    Expression<int>? createdAtMillis,
  }) {
    return RawValuesInsertable({
      if (revisionLocalId != null) 'revision_local_id': revisionLocalId,
      if (draftRecordId != null) 'draft_record_id': draftRecordId,
      if (body != null) 'body': body,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (remoteRevisionId != null) 'remote_revision_id': remoteRevisionId,
      if (createdAtMillis != null) 'created_at_millis': createdAtMillis,
    });
  }

  AmcRecordRevisionsCompanion copyWith({
    Value<int>? revisionLocalId,
    Value<int>? draftRecordId,
    Value<String>? body,
    Value<String>? idempotencyKey,
    Value<String?>? remoteRevisionId,
    Value<int>? createdAtMillis,
  }) {
    return AmcRecordRevisionsCompanion(
      revisionLocalId: revisionLocalId ?? this.revisionLocalId,
      draftRecordId: draftRecordId ?? this.draftRecordId,
      body: body ?? this.body,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      remoteRevisionId: remoteRevisionId ?? this.remoteRevisionId,
      createdAtMillis: createdAtMillis ?? this.createdAtMillis,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (revisionLocalId.present) {
      map['revision_local_id'] = Variable<int>(revisionLocalId.value);
    }
    if (draftRecordId.present) {
      map['draft_record_id'] = Variable<int>(draftRecordId.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (remoteRevisionId.present) {
      map['remote_revision_id'] = Variable<String>(remoteRevisionId.value);
    }
    if (createdAtMillis.present) {
      map['created_at_millis'] = Variable<int>(createdAtMillis.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AmcRecordRevisionsCompanion(')
          ..write('revisionLocalId: $revisionLocalId, ')
          ..write('draftRecordId: $draftRecordId, ')
          ..write('body: $body, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('remoteRevisionId: $remoteRevisionId, ')
          ..write('createdAtMillis: $createdAtMillis')
          ..write(')'))
        .toString();
  }
}

class $AmcAttachmentQueueTable extends AmcAttachmentQueue
    with TableInfo<$AmcAttachmentQueueTable, AmcAttachment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AmcAttachmentQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _attachmentIdMeta = const VerificationMeta(
    'attachmentId',
  );
  @override
  late final GeneratedColumn<int> attachmentId = GeneratedColumn<int>(
    'attachment_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _draftRecordIdMeta = const VerificationMeta(
    'draftRecordId',
  );
  @override
  late final GeneratedColumn<int> draftRecordId = GeneratedColumn<int>(
    'draft_record_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES amc_draft_records (draft_record_id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _localUriMeta = const VerificationMeta(
    'localUri',
  );
  @override
  late final GeneratedColumn<String> localUri = GeneratedColumn<String>(
    'local_uri',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<AmcAttachmentState, String>
  state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<AmcAttachmentState>($AmcAttachmentQueueTable.$converterstate);
  static const VerificationMeta _storagePathMeta = const VerificationMeta(
    'storagePath',
  );
  @override
  late final GeneratedColumn<String> storagePath = GeneratedColumn<String>(
    'storage_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remoteAttachmentIdMeta =
      const VerificationMeta('remoteAttachmentId');
  @override
  late final GeneratedColumn<String> remoteAttachmentId =
      GeneratedColumn<String>(
        'remote_attachment_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _attemptNumberMeta = const VerificationMeta(
    'attemptNumber',
  );
  @override
  late final GeneratedColumn<int> attemptNumber = GeneratedColumn<int>(
    'attempt_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorCodeMeta = const VerificationMeta(
    'lastErrorCode',
  );
  @override
  late final GeneratedColumn<String> lastErrorCode = GeneratedColumn<String>(
    'last_error_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _expiresAtMillisMeta = const VerificationMeta(
    'expiresAtMillis',
  );
  @override
  late final GeneratedColumn<int> expiresAtMillis = GeneratedColumn<int>(
    'expires_at_millis',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _checksumMeta = const VerificationMeta(
    'checksum',
  );
  @override
  late final GeneratedColumn<String> checksum = GeneratedColumn<String>(
    'checksum',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    attachmentId,
    draftRecordId,
    localUri,
    mimeType,
    state,
    storagePath,
    remoteAttachmentId,
    attemptNumber,
    lastErrorCode,
    expiresAtMillis,
    checksum,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'amc_attachment_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<AmcAttachment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('attachment_id')) {
      context.handle(
        _attachmentIdMeta,
        attachmentId.isAcceptableOrUnknown(
          data['attachment_id']!,
          _attachmentIdMeta,
        ),
      );
    }
    if (data.containsKey('draft_record_id')) {
      context.handle(
        _draftRecordIdMeta,
        draftRecordId.isAcceptableOrUnknown(
          data['draft_record_id']!,
          _draftRecordIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_draftRecordIdMeta);
    }
    if (data.containsKey('local_uri')) {
      context.handle(
        _localUriMeta,
        localUri.isAcceptableOrUnknown(data['local_uri']!, _localUriMeta),
      );
    } else if (isInserting) {
      context.missing(_localUriMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    if (data.containsKey('storage_path')) {
      context.handle(
        _storagePathMeta,
        storagePath.isAcceptableOrUnknown(
          data['storage_path']!,
          _storagePathMeta,
        ),
      );
    }
    if (data.containsKey('remote_attachment_id')) {
      context.handle(
        _remoteAttachmentIdMeta,
        remoteAttachmentId.isAcceptableOrUnknown(
          data['remote_attachment_id']!,
          _remoteAttachmentIdMeta,
        ),
      );
    }
    if (data.containsKey('attempt_number')) {
      context.handle(
        _attemptNumberMeta,
        attemptNumber.isAcceptableOrUnknown(
          data['attempt_number']!,
          _attemptNumberMeta,
        ),
      );
    }
    if (data.containsKey('last_error_code')) {
      context.handle(
        _lastErrorCodeMeta,
        lastErrorCode.isAcceptableOrUnknown(
          data['last_error_code']!,
          _lastErrorCodeMeta,
        ),
      );
    }
    if (data.containsKey('expires_at_millis')) {
      context.handle(
        _expiresAtMillisMeta,
        expiresAtMillis.isAcceptableOrUnknown(
          data['expires_at_millis']!,
          _expiresAtMillisMeta,
        ),
      );
    }
    if (data.containsKey('checksum')) {
      context.handle(
        _checksumMeta,
        checksum.isAcceptableOrUnknown(data['checksum']!, _checksumMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {attachmentId};
  @override
  AmcAttachment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AmcAttachment(
      attachmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attachment_id'],
      )!,
      draftRecordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}draft_record_id'],
      )!,
      localUri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_uri'],
      )!,
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      )!,
      state: $AmcAttachmentQueueTable.$converterstate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}state'],
        )!,
      ),
      storagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}storage_path'],
      ),
      remoteAttachmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_attachment_id'],
      ),
      attemptNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_number'],
      )!,
      lastErrorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error_code'],
      ),
      expiresAtMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expires_at_millis'],
      ),
      checksum: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}checksum'],
      ),
    );
  }

  @override
  $AmcAttachmentQueueTable createAlias(String alias) {
    return $AmcAttachmentQueueTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AmcAttachmentState, String, String>
  $converterstate = const EnumNameConverter<AmcAttachmentState>(
    AmcAttachmentState.values,
  );
}

class AmcAttachment extends DataClass implements Insertable<AmcAttachment> {
  final int attachmentId;
  final int draftRecordId;
  final String localUri;
  final String mimeType;
  final AmcAttachmentState state;
  final String? storagePath;
  final String? remoteAttachmentId;
  final int attemptNumber;
  final String? lastErrorCode;
  final int? expiresAtMillis;
  final String? checksum;
  const AmcAttachment({
    required this.attachmentId,
    required this.draftRecordId,
    required this.localUri,
    required this.mimeType,
    required this.state,
    this.storagePath,
    this.remoteAttachmentId,
    required this.attemptNumber,
    this.lastErrorCode,
    this.expiresAtMillis,
    this.checksum,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['attachment_id'] = Variable<int>(attachmentId);
    map['draft_record_id'] = Variable<int>(draftRecordId);
    map['local_uri'] = Variable<String>(localUri);
    map['mime_type'] = Variable<String>(mimeType);
    {
      map['state'] = Variable<String>(
        $AmcAttachmentQueueTable.$converterstate.toSql(state),
      );
    }
    if (!nullToAbsent || storagePath != null) {
      map['storage_path'] = Variable<String>(storagePath);
    }
    if (!nullToAbsent || remoteAttachmentId != null) {
      map['remote_attachment_id'] = Variable<String>(remoteAttachmentId);
    }
    map['attempt_number'] = Variable<int>(attemptNumber);
    if (!nullToAbsent || lastErrorCode != null) {
      map['last_error_code'] = Variable<String>(lastErrorCode);
    }
    if (!nullToAbsent || expiresAtMillis != null) {
      map['expires_at_millis'] = Variable<int>(expiresAtMillis);
    }
    if (!nullToAbsent || checksum != null) {
      map['checksum'] = Variable<String>(checksum);
    }
    return map;
  }

  AmcAttachmentQueueCompanion toCompanion(bool nullToAbsent) {
    return AmcAttachmentQueueCompanion(
      attachmentId: Value(attachmentId),
      draftRecordId: Value(draftRecordId),
      localUri: Value(localUri),
      mimeType: Value(mimeType),
      state: Value(state),
      storagePath: storagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(storagePath),
      remoteAttachmentId: remoteAttachmentId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteAttachmentId),
      attemptNumber: Value(attemptNumber),
      lastErrorCode: lastErrorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(lastErrorCode),
      expiresAtMillis: expiresAtMillis == null && nullToAbsent
          ? const Value.absent()
          : Value(expiresAtMillis),
      checksum: checksum == null && nullToAbsent
          ? const Value.absent()
          : Value(checksum),
    );
  }

  factory AmcAttachment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AmcAttachment(
      attachmentId: serializer.fromJson<int>(json['attachmentId']),
      draftRecordId: serializer.fromJson<int>(json['draftRecordId']),
      localUri: serializer.fromJson<String>(json['localUri']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      state: $AmcAttachmentQueueTable.$converterstate.fromJson(
        serializer.fromJson<String>(json['state']),
      ),
      storagePath: serializer.fromJson<String?>(json['storagePath']),
      remoteAttachmentId: serializer.fromJson<String?>(
        json['remoteAttachmentId'],
      ),
      attemptNumber: serializer.fromJson<int>(json['attemptNumber']),
      lastErrorCode: serializer.fromJson<String?>(json['lastErrorCode']),
      expiresAtMillis: serializer.fromJson<int?>(json['expiresAtMillis']),
      checksum: serializer.fromJson<String?>(json['checksum']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'attachmentId': serializer.toJson<int>(attachmentId),
      'draftRecordId': serializer.toJson<int>(draftRecordId),
      'localUri': serializer.toJson<String>(localUri),
      'mimeType': serializer.toJson<String>(mimeType),
      'state': serializer.toJson<String>(
        $AmcAttachmentQueueTable.$converterstate.toJson(state),
      ),
      'storagePath': serializer.toJson<String?>(storagePath),
      'remoteAttachmentId': serializer.toJson<String?>(remoteAttachmentId),
      'attemptNumber': serializer.toJson<int>(attemptNumber),
      'lastErrorCode': serializer.toJson<String?>(lastErrorCode),
      'expiresAtMillis': serializer.toJson<int?>(expiresAtMillis),
      'checksum': serializer.toJson<String?>(checksum),
    };
  }

  AmcAttachment copyWith({
    int? attachmentId,
    int? draftRecordId,
    String? localUri,
    String? mimeType,
    AmcAttachmentState? state,
    Value<String?> storagePath = const Value.absent(),
    Value<String?> remoteAttachmentId = const Value.absent(),
    int? attemptNumber,
    Value<String?> lastErrorCode = const Value.absent(),
    Value<int?> expiresAtMillis = const Value.absent(),
    Value<String?> checksum = const Value.absent(),
  }) => AmcAttachment(
    attachmentId: attachmentId ?? this.attachmentId,
    draftRecordId: draftRecordId ?? this.draftRecordId,
    localUri: localUri ?? this.localUri,
    mimeType: mimeType ?? this.mimeType,
    state: state ?? this.state,
    storagePath: storagePath.present ? storagePath.value : this.storagePath,
    remoteAttachmentId: remoteAttachmentId.present
        ? remoteAttachmentId.value
        : this.remoteAttachmentId,
    attemptNumber: attemptNumber ?? this.attemptNumber,
    lastErrorCode: lastErrorCode.present
        ? lastErrorCode.value
        : this.lastErrorCode,
    expiresAtMillis: expiresAtMillis.present
        ? expiresAtMillis.value
        : this.expiresAtMillis,
    checksum: checksum.present ? checksum.value : this.checksum,
  );
  AmcAttachment copyWithCompanion(AmcAttachmentQueueCompanion data) {
    return AmcAttachment(
      attachmentId: data.attachmentId.present
          ? data.attachmentId.value
          : this.attachmentId,
      draftRecordId: data.draftRecordId.present
          ? data.draftRecordId.value
          : this.draftRecordId,
      localUri: data.localUri.present ? data.localUri.value : this.localUri,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      state: data.state.present ? data.state.value : this.state,
      storagePath: data.storagePath.present
          ? data.storagePath.value
          : this.storagePath,
      remoteAttachmentId: data.remoteAttachmentId.present
          ? data.remoteAttachmentId.value
          : this.remoteAttachmentId,
      attemptNumber: data.attemptNumber.present
          ? data.attemptNumber.value
          : this.attemptNumber,
      lastErrorCode: data.lastErrorCode.present
          ? data.lastErrorCode.value
          : this.lastErrorCode,
      expiresAtMillis: data.expiresAtMillis.present
          ? data.expiresAtMillis.value
          : this.expiresAtMillis,
      checksum: data.checksum.present ? data.checksum.value : this.checksum,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AmcAttachment(')
          ..write('attachmentId: $attachmentId, ')
          ..write('draftRecordId: $draftRecordId, ')
          ..write('localUri: $localUri, ')
          ..write('mimeType: $mimeType, ')
          ..write('state: $state, ')
          ..write('storagePath: $storagePath, ')
          ..write('remoteAttachmentId: $remoteAttachmentId, ')
          ..write('attemptNumber: $attemptNumber, ')
          ..write('lastErrorCode: $lastErrorCode, ')
          ..write('expiresAtMillis: $expiresAtMillis, ')
          ..write('checksum: $checksum')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    attachmentId,
    draftRecordId,
    localUri,
    mimeType,
    state,
    storagePath,
    remoteAttachmentId,
    attemptNumber,
    lastErrorCode,
    expiresAtMillis,
    checksum,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AmcAttachment &&
          other.attachmentId == this.attachmentId &&
          other.draftRecordId == this.draftRecordId &&
          other.localUri == this.localUri &&
          other.mimeType == this.mimeType &&
          other.state == this.state &&
          other.storagePath == this.storagePath &&
          other.remoteAttachmentId == this.remoteAttachmentId &&
          other.attemptNumber == this.attemptNumber &&
          other.lastErrorCode == this.lastErrorCode &&
          other.expiresAtMillis == this.expiresAtMillis &&
          other.checksum == this.checksum);
}

class AmcAttachmentQueueCompanion extends UpdateCompanion<AmcAttachment> {
  final Value<int> attachmentId;
  final Value<int> draftRecordId;
  final Value<String> localUri;
  final Value<String> mimeType;
  final Value<AmcAttachmentState> state;
  final Value<String?> storagePath;
  final Value<String?> remoteAttachmentId;
  final Value<int> attemptNumber;
  final Value<String?> lastErrorCode;
  final Value<int?> expiresAtMillis;
  final Value<String?> checksum;
  const AmcAttachmentQueueCompanion({
    this.attachmentId = const Value.absent(),
    this.draftRecordId = const Value.absent(),
    this.localUri = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.state = const Value.absent(),
    this.storagePath = const Value.absent(),
    this.remoteAttachmentId = const Value.absent(),
    this.attemptNumber = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
    this.expiresAtMillis = const Value.absent(),
    this.checksum = const Value.absent(),
  });
  AmcAttachmentQueueCompanion.insert({
    this.attachmentId = const Value.absent(),
    required int draftRecordId,
    required String localUri,
    required String mimeType,
    required AmcAttachmentState state,
    this.storagePath = const Value.absent(),
    this.remoteAttachmentId = const Value.absent(),
    this.attemptNumber = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
    this.expiresAtMillis = const Value.absent(),
    this.checksum = const Value.absent(),
  }) : draftRecordId = Value(draftRecordId),
       localUri = Value(localUri),
       mimeType = Value(mimeType),
       state = Value(state);
  static Insertable<AmcAttachment> custom({
    Expression<int>? attachmentId,
    Expression<int>? draftRecordId,
    Expression<String>? localUri,
    Expression<String>? mimeType,
    Expression<String>? state,
    Expression<String>? storagePath,
    Expression<String>? remoteAttachmentId,
    Expression<int>? attemptNumber,
    Expression<String>? lastErrorCode,
    Expression<int>? expiresAtMillis,
    Expression<String>? checksum,
  }) {
    return RawValuesInsertable({
      if (attachmentId != null) 'attachment_id': attachmentId,
      if (draftRecordId != null) 'draft_record_id': draftRecordId,
      if (localUri != null) 'local_uri': localUri,
      if (mimeType != null) 'mime_type': mimeType,
      if (state != null) 'state': state,
      if (storagePath != null) 'storage_path': storagePath,
      if (remoteAttachmentId != null)
        'remote_attachment_id': remoteAttachmentId,
      if (attemptNumber != null) 'attempt_number': attemptNumber,
      if (lastErrorCode != null) 'last_error_code': lastErrorCode,
      if (expiresAtMillis != null) 'expires_at_millis': expiresAtMillis,
      if (checksum != null) 'checksum': checksum,
    });
  }

  AmcAttachmentQueueCompanion copyWith({
    Value<int>? attachmentId,
    Value<int>? draftRecordId,
    Value<String>? localUri,
    Value<String>? mimeType,
    Value<AmcAttachmentState>? state,
    Value<String?>? storagePath,
    Value<String?>? remoteAttachmentId,
    Value<int>? attemptNumber,
    Value<String?>? lastErrorCode,
    Value<int?>? expiresAtMillis,
    Value<String?>? checksum,
  }) {
    return AmcAttachmentQueueCompanion(
      attachmentId: attachmentId ?? this.attachmentId,
      draftRecordId: draftRecordId ?? this.draftRecordId,
      localUri: localUri ?? this.localUri,
      mimeType: mimeType ?? this.mimeType,
      state: state ?? this.state,
      storagePath: storagePath ?? this.storagePath,
      remoteAttachmentId: remoteAttachmentId ?? this.remoteAttachmentId,
      attemptNumber: attemptNumber ?? this.attemptNumber,
      lastErrorCode: lastErrorCode ?? this.lastErrorCode,
      expiresAtMillis: expiresAtMillis ?? this.expiresAtMillis,
      checksum: checksum ?? this.checksum,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (attachmentId.present) {
      map['attachment_id'] = Variable<int>(attachmentId.value);
    }
    if (draftRecordId.present) {
      map['draft_record_id'] = Variable<int>(draftRecordId.value);
    }
    if (localUri.present) {
      map['local_uri'] = Variable<String>(localUri.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(
        $AmcAttachmentQueueTable.$converterstate.toSql(state.value),
      );
    }
    if (storagePath.present) {
      map['storage_path'] = Variable<String>(storagePath.value);
    }
    if (remoteAttachmentId.present) {
      map['remote_attachment_id'] = Variable<String>(remoteAttachmentId.value);
    }
    if (attemptNumber.present) {
      map['attempt_number'] = Variable<int>(attemptNumber.value);
    }
    if (lastErrorCode.present) {
      map['last_error_code'] = Variable<String>(lastErrorCode.value);
    }
    if (expiresAtMillis.present) {
      map['expires_at_millis'] = Variable<int>(expiresAtMillis.value);
    }
    if (checksum.present) {
      map['checksum'] = Variable<String>(checksum.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AmcAttachmentQueueCompanion(')
          ..write('attachmentId: $attachmentId, ')
          ..write('draftRecordId: $draftRecordId, ')
          ..write('localUri: $localUri, ')
          ..write('mimeType: $mimeType, ')
          ..write('state: $state, ')
          ..write('storagePath: $storagePath, ')
          ..write('remoteAttachmentId: $remoteAttachmentId, ')
          ..write('attemptNumber: $attemptNumber, ')
          ..write('lastErrorCode: $lastErrorCode, ')
          ..write('expiresAtMillis: $expiresAtMillis, ')
          ..write('checksum: $checksum')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $EventsTable events = $EventsTable(this);
  late final $ObservationEventsTable observationEvents =
      $ObservationEventsTable(this);
  late final $RecordsTable records = $RecordsTable(this);
  late final $PhotosTable photos = $PhotosTable(this);
  late final $MemosTable memos = $MemosTable(this);
  late final $AmcDraftRecordsTable amcDraftRecords = $AmcDraftRecordsTable(
    this,
  );
  late final $AmcRecordRevisionsTable amcRecordRevisions =
      $AmcRecordRevisionsTable(this);
  late final $AmcAttachmentQueueTable amcAttachmentQueue =
      $AmcAttachmentQueueTable(this);
  late final Index idxRecordsObsEventId = Index(
    'idx_records_obs_event_id',
    'CREATE INDEX idx_records_obs_event_id ON records (obs_event_id)',
  );
  late final Index idxPhotosRecordId = Index(
    'idx_photos_record_id',
    'CREATE INDEX idx_photos_record_id ON photos (record_id)',
  );
  late final Index idxMemosRecordId = Index(
    'idx_memos_record_id',
    'CREATE INDEX idx_memos_record_id ON memos (record_id)',
  );
  late final Index idxAmcRevisionsDraft = Index(
    'idx_amc_revisions_draft',
    'CREATE INDEX idx_amc_revisions_draft ON amc_record_revisions (draft_record_id)',
  );
  late final Index idxAmcAttachmentsDraft = Index(
    'idx_amc_attachments_draft',
    'CREATE INDEX idx_amc_attachments_draft ON amc_attachment_queue (draft_record_id)',
  );
  late final EventDao eventDao = EventDao(this as AppDatabase);
  late final ObservationEventDao observationEventDao = ObservationEventDao(
    this as AppDatabase,
  );
  late final RecordDao recordDao = RecordDao(this as AppDatabase);
  late final PhotoDao photoDao = PhotoDao(this as AppDatabase);
  late final MemoDao memoDao = MemoDao(this as AppDatabase);
  late final AnalyticsDao analyticsDao = AnalyticsDao(this as AppDatabase);
  late final AmcDraftDao amcDraftDao = AmcDraftDao(this as AppDatabase);
  late final AmcAttachmentDao amcAttachmentDao = AmcAttachmentDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    events,
    observationEvents,
    records,
    photos,
    memos,
    amcDraftRecords,
    amcRecordRevisions,
    amcAttachmentQueue,
    idxRecordsObsEventId,
    idxPhotosRecordId,
    idxMemosRecordId,
    idxAmcRevisionsDraft,
    idxAmcAttachmentsDraft,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'observation_events',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('records', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'records',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('photos', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'records',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('memos', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'amc_draft_records',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('amc_record_revisions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'amc_draft_records',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('amc_attachment_queue', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$EventsTableCreateCompanionBuilder =
    EventsCompanion Function({
      Value<int> eventId,
      required String googleEventId,
      required String title,
      required int startTime,
      required int endTime,
    });
typedef $$EventsTableUpdateCompanionBuilder =
    EventsCompanion Function({
      Value<int> eventId,
      Value<String> googleEventId,
      Value<String> title,
      Value<int> startTime,
      Value<int> endTime,
    });

class $$EventsTableFilterComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get googleEventId => $composableBuilder(
    column: $table.googleEventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EventsTableOrderingComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get googleEventId => $composableBuilder(
    column: $table.googleEventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<String> get googleEventId => $composableBuilder(
    column: $table.googleEventId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<int> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);
}

class $$EventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EventsTable,
          Event,
          $$EventsTableFilterComposer,
          $$EventsTableOrderingComposer,
          $$EventsTableAnnotationComposer,
          $$EventsTableCreateCompanionBuilder,
          $$EventsTableUpdateCompanionBuilder,
          (Event, BaseReferences<_$AppDatabase, $EventsTable, Event>),
          Event,
          PrefetchHooks Function()
        > {
  $$EventsTableTableManager(_$AppDatabase db, $EventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> eventId = const Value.absent(),
                Value<String> googleEventId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> startTime = const Value.absent(),
                Value<int> endTime = const Value.absent(),
              }) => EventsCompanion(
                eventId: eventId,
                googleEventId: googleEventId,
                title: title,
                startTime: startTime,
                endTime: endTime,
              ),
          createCompanionCallback:
              ({
                Value<int> eventId = const Value.absent(),
                required String googleEventId,
                required String title,
                required int startTime,
                required int endTime,
              }) => EventsCompanion.insert(
                eventId: eventId,
                googleEventId: googleEventId,
                title: title,
                startTime: startTime,
                endTime: endTime,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EventsTable,
      Event,
      $$EventsTableFilterComposer,
      $$EventsTableOrderingComposer,
      $$EventsTableAnnotationComposer,
      $$EventsTableCreateCompanionBuilder,
      $$EventsTableUpdateCompanionBuilder,
      (Event, BaseReferences<_$AppDatabase, $EventsTable, Event>),
      Event,
      PrefetchHooks Function()
    >;
typedef $$ObservationEventsTableCreateCompanionBuilder =
    ObservationEventsCompanion Function({
      Value<int> obsEventId,
      Value<String?> googleEventId,
      required String title,
      required int startTime,
      required int endTime,
    });
typedef $$ObservationEventsTableUpdateCompanionBuilder =
    ObservationEventsCompanion Function({
      Value<int> obsEventId,
      Value<String?> googleEventId,
      Value<String> title,
      Value<int> startTime,
      Value<int> endTime,
    });

final class $$ObservationEventsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ObservationEventsTable,
          ObservationEvent
        > {
  $$ObservationEventsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$RecordsTable, List<Record>> _recordsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.records,
    aliasName: $_aliasNameGenerator(
      db.observationEvents.obsEventId,
      db.records.obsEventId,
    ),
  );

  $$RecordsTableProcessedTableManager get recordsRefs {
    final manager = $$RecordsTableTableManager($_db, $_db.records).filter(
      (f) =>
          f.obsEventId.obsEventId.sqlEquals($_itemColumn<int>('obs_event_id')!),
    );

    final cache = $_typedResult.readTableOrNull(_recordsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ObservationEventsTableFilterComposer
    extends Composer<_$AppDatabase, $ObservationEventsTable> {
  $$ObservationEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get obsEventId => $composableBuilder(
    column: $table.obsEventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get googleEventId => $composableBuilder(
    column: $table.googleEventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> recordsRefs(
    Expression<bool> Function($$RecordsTableFilterComposer f) f,
  ) {
    final $$RecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.obsEventId,
      referencedTable: $db.records,
      getReferencedColumn: (t) => t.obsEventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecordsTableFilterComposer(
            $db: $db,
            $table: $db.records,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ObservationEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $ObservationEventsTable> {
  $$ObservationEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get obsEventId => $composableBuilder(
    column: $table.obsEventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get googleEventId => $composableBuilder(
    column: $table.googleEventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ObservationEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ObservationEventsTable> {
  $$ObservationEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get obsEventId => $composableBuilder(
    column: $table.obsEventId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get googleEventId => $composableBuilder(
    column: $table.googleEventId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<int> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  Expression<T> recordsRefs<T extends Object>(
    Expression<T> Function($$RecordsTableAnnotationComposer a) f,
  ) {
    final $$RecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.obsEventId,
      referencedTable: $db.records,
      getReferencedColumn: (t) => t.obsEventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.records,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ObservationEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ObservationEventsTable,
          ObservationEvent,
          $$ObservationEventsTableFilterComposer,
          $$ObservationEventsTableOrderingComposer,
          $$ObservationEventsTableAnnotationComposer,
          $$ObservationEventsTableCreateCompanionBuilder,
          $$ObservationEventsTableUpdateCompanionBuilder,
          (ObservationEvent, $$ObservationEventsTableReferences),
          ObservationEvent,
          PrefetchHooks Function({bool recordsRefs})
        > {
  $$ObservationEventsTableTableManager(
    _$AppDatabase db,
    $ObservationEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ObservationEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ObservationEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ObservationEventsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> obsEventId = const Value.absent(),
                Value<String?> googleEventId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> startTime = const Value.absent(),
                Value<int> endTime = const Value.absent(),
              }) => ObservationEventsCompanion(
                obsEventId: obsEventId,
                googleEventId: googleEventId,
                title: title,
                startTime: startTime,
                endTime: endTime,
              ),
          createCompanionCallback:
              ({
                Value<int> obsEventId = const Value.absent(),
                Value<String?> googleEventId = const Value.absent(),
                required String title,
                required int startTime,
                required int endTime,
              }) => ObservationEventsCompanion.insert(
                obsEventId: obsEventId,
                googleEventId: googleEventId,
                title: title,
                startTime: startTime,
                endTime: endTime,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ObservationEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({recordsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (recordsRefs) db.records],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (recordsRefs)
                    await $_getPrefetchedData<
                      ObservationEvent,
                      $ObservationEventsTable,
                      Record
                    >(
                      currentTable: table,
                      referencedTable: $$ObservationEventsTableReferences
                          ._recordsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ObservationEventsTableReferences(
                            db,
                            table,
                            p0,
                          ).recordsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.obsEventId == item.obsEventId,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ObservationEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ObservationEventsTable,
      ObservationEvent,
      $$ObservationEventsTableFilterComposer,
      $$ObservationEventsTableOrderingComposer,
      $$ObservationEventsTableAnnotationComposer,
      $$ObservationEventsTableCreateCompanionBuilder,
      $$ObservationEventsTableUpdateCompanionBuilder,
      (ObservationEvent, $$ObservationEventsTableReferences),
      ObservationEvent,
      PrefetchHooks Function({bool recordsRefs})
    >;
typedef $$RecordsTableCreateCompanionBuilder =
    RecordsCompanion Function({
      Value<int> recordId,
      required int obsEventId,
      required int recordTime,
      required RecordType recordType,
    });
typedef $$RecordsTableUpdateCompanionBuilder =
    RecordsCompanion Function({
      Value<int> recordId,
      Value<int> obsEventId,
      Value<int> recordTime,
      Value<RecordType> recordType,
    });

final class $$RecordsTableReferences
    extends BaseReferences<_$AppDatabase, $RecordsTable, Record> {
  $$RecordsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ObservationEventsTable _obsEventIdTable(_$AppDatabase db) =>
      db.observationEvents.createAlias(
        $_aliasNameGenerator(
          db.records.obsEventId,
          db.observationEvents.obsEventId,
        ),
      );

  $$ObservationEventsTableProcessedTableManager get obsEventId {
    final $_column = $_itemColumn<int>('obs_event_id')!;

    final manager = $$ObservationEventsTableTableManager(
      $_db,
      $_db.observationEvents,
    ).filter((f) => f.obsEventId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_obsEventIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$PhotosTable, List<Photo>> _photosRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.photos,
    aliasName: $_aliasNameGenerator(db.records.recordId, db.photos.recordId),
  );

  $$PhotosTableProcessedTableManager get photosRefs {
    final manager = $$PhotosTableTableManager($_db, $_db.photos).filter(
      (f) => f.recordId.recordId.sqlEquals($_itemColumn<int>('record_id')!),
    );

    final cache = $_typedResult.readTableOrNull(_photosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MemosTable, List<Memo>> _memosRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.memos,
    aliasName: $_aliasNameGenerator(db.records.recordId, db.memos.recordId),
  );

  $$MemosTableProcessedTableManager get memosRefs {
    final manager = $$MemosTableTableManager($_db, $_db.memos).filter(
      (f) => f.recordId.recordId.sqlEquals($_itemColumn<int>('record_id')!),
    );

    final cache = $_typedResult.readTableOrNull(_memosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RecordsTableFilterComposer
    extends Composer<_$AppDatabase, $RecordsTable> {
  $$RecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recordTime => $composableBuilder(
    column: $table.recordTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<RecordType, RecordType, String>
  get recordType => $composableBuilder(
    column: $table.recordType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  $$ObservationEventsTableFilterComposer get obsEventId {
    final $$ObservationEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.obsEventId,
      referencedTable: $db.observationEvents,
      getReferencedColumn: (t) => t.obsEventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ObservationEventsTableFilterComposer(
            $db: $db,
            $table: $db.observationEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> photosRefs(
    Expression<bool> Function($$PhotosTableFilterComposer f) f,
  ) {
    final $$PhotosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordId,
      referencedTable: $db.photos,
      getReferencedColumn: (t) => t.recordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PhotosTableFilterComposer(
            $db: $db,
            $table: $db.photos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> memosRefs(
    Expression<bool> Function($$MemosTableFilterComposer f) f,
  ) {
    final $$MemosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordId,
      referencedTable: $db.memos,
      getReferencedColumn: (t) => t.recordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MemosTableFilterComposer(
            $db: $db,
            $table: $db.memos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecordsTable> {
  $$RecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recordTime => $composableBuilder(
    column: $table.recordTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordType => $composableBuilder(
    column: $table.recordType,
    builder: (column) => ColumnOrderings(column),
  );

  $$ObservationEventsTableOrderingComposer get obsEventId {
    final $$ObservationEventsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.obsEventId,
      referencedTable: $db.observationEvents,
      getReferencedColumn: (t) => t.obsEventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ObservationEventsTableOrderingComposer(
            $db: $db,
            $table: $db.observationEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecordsTable> {
  $$RecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get recordId =>
      $composableBuilder(column: $table.recordId, builder: (column) => column);

  GeneratedColumn<int> get recordTime => $composableBuilder(
    column: $table.recordTime,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<RecordType, String> get recordType =>
      $composableBuilder(
        column: $table.recordType,
        builder: (column) => column,
      );

  $$ObservationEventsTableAnnotationComposer get obsEventId {
    final $$ObservationEventsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.obsEventId,
          referencedTable: $db.observationEvents,
          getReferencedColumn: (t) => t.obsEventId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ObservationEventsTableAnnotationComposer(
                $db: $db,
                $table: $db.observationEvents,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  Expression<T> photosRefs<T extends Object>(
    Expression<T> Function($$PhotosTableAnnotationComposer a) f,
  ) {
    final $$PhotosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordId,
      referencedTable: $db.photos,
      getReferencedColumn: (t) => t.recordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PhotosTableAnnotationComposer(
            $db: $db,
            $table: $db.photos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> memosRefs<T extends Object>(
    Expression<T> Function($$MemosTableAnnotationComposer a) f,
  ) {
    final $$MemosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordId,
      referencedTable: $db.memos,
      getReferencedColumn: (t) => t.recordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MemosTableAnnotationComposer(
            $db: $db,
            $table: $db.memos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecordsTable,
          Record,
          $$RecordsTableFilterComposer,
          $$RecordsTableOrderingComposer,
          $$RecordsTableAnnotationComposer,
          $$RecordsTableCreateCompanionBuilder,
          $$RecordsTableUpdateCompanionBuilder,
          (Record, $$RecordsTableReferences),
          Record,
          PrefetchHooks Function({
            bool obsEventId,
            bool photosRefs,
            bool memosRefs,
          })
        > {
  $$RecordsTableTableManager(_$AppDatabase db, $RecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> recordId = const Value.absent(),
                Value<int> obsEventId = const Value.absent(),
                Value<int> recordTime = const Value.absent(),
                Value<RecordType> recordType = const Value.absent(),
              }) => RecordsCompanion(
                recordId: recordId,
                obsEventId: obsEventId,
                recordTime: recordTime,
                recordType: recordType,
              ),
          createCompanionCallback:
              ({
                Value<int> recordId = const Value.absent(),
                required int obsEventId,
                required int recordTime,
                required RecordType recordType,
              }) => RecordsCompanion.insert(
                recordId: recordId,
                obsEventId: obsEventId,
                recordTime: recordTime,
                recordType: recordType,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({obsEventId = false, photosRefs = false, memosRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (photosRefs) db.photos,
                    if (memosRefs) db.memos,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (obsEventId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.obsEventId,
                                    referencedTable: $$RecordsTableReferences
                                        ._obsEventIdTable(db),
                                    referencedColumn: $$RecordsTableReferences
                                        ._obsEventIdTable(db)
                                        .obsEventId,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (photosRefs)
                        await $_getPrefetchedData<Record, $RecordsTable, Photo>(
                          currentTable: table,
                          referencedTable: $$RecordsTableReferences
                              ._photosRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RecordsTableReferences(
                                db,
                                table,
                                p0,
                              ).photosRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.recordId == item.recordId,
                              ),
                          typedResults: items,
                        ),
                      if (memosRefs)
                        await $_getPrefetchedData<Record, $RecordsTable, Memo>(
                          currentTable: table,
                          referencedTable: $$RecordsTableReferences
                              ._memosRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RecordsTableReferences(db, table, p0).memosRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.recordId == item.recordId,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$RecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecordsTable,
      Record,
      $$RecordsTableFilterComposer,
      $$RecordsTableOrderingComposer,
      $$RecordsTableAnnotationComposer,
      $$RecordsTableCreateCompanionBuilder,
      $$RecordsTableUpdateCompanionBuilder,
      (Record, $$RecordsTableReferences),
      Record,
      PrefetchHooks Function({bool obsEventId, bool photosRefs, bool memosRefs})
    >;
typedef $$PhotosTableCreateCompanionBuilder =
    PhotosCompanion Function({
      Value<int> photoId,
      required int recordId,
      required String filePath,
    });
typedef $$PhotosTableUpdateCompanionBuilder =
    PhotosCompanion Function({
      Value<int> photoId,
      Value<int> recordId,
      Value<String> filePath,
    });

final class $$PhotosTableReferences
    extends BaseReferences<_$AppDatabase, $PhotosTable, Photo> {
  $$PhotosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RecordsTable _recordIdTable(_$AppDatabase db) =>
      db.records.createAlias(
        $_aliasNameGenerator(db.photos.recordId, db.records.recordId),
      );

  $$RecordsTableProcessedTableManager get recordId {
    final $_column = $_itemColumn<int>('record_id')!;

    final manager = $$RecordsTableTableManager(
      $_db,
      $_db.records,
    ).filter((f) => f.recordId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PhotosTableFilterComposer
    extends Composer<_$AppDatabase, $PhotosTable> {
  $$PhotosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get photoId => $composableBuilder(
    column: $table.photoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  $$RecordsTableFilterComposer get recordId {
    final $$RecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordId,
      referencedTable: $db.records,
      getReferencedColumn: (t) => t.recordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecordsTableFilterComposer(
            $db: $db,
            $table: $db.records,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PhotosTableOrderingComposer
    extends Composer<_$AppDatabase, $PhotosTable> {
  $$PhotosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get photoId => $composableBuilder(
    column: $table.photoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  $$RecordsTableOrderingComposer get recordId {
    final $$RecordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordId,
      referencedTable: $db.records,
      getReferencedColumn: (t) => t.recordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecordsTableOrderingComposer(
            $db: $db,
            $table: $db.records,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PhotosTableAnnotationComposer
    extends Composer<_$AppDatabase, $PhotosTable> {
  $$PhotosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get photoId =>
      $composableBuilder(column: $table.photoId, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  $$RecordsTableAnnotationComposer get recordId {
    final $$RecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordId,
      referencedTable: $db.records,
      getReferencedColumn: (t) => t.recordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.records,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PhotosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PhotosTable,
          Photo,
          $$PhotosTableFilterComposer,
          $$PhotosTableOrderingComposer,
          $$PhotosTableAnnotationComposer,
          $$PhotosTableCreateCompanionBuilder,
          $$PhotosTableUpdateCompanionBuilder,
          (Photo, $$PhotosTableReferences),
          Photo,
          PrefetchHooks Function({bool recordId})
        > {
  $$PhotosTableTableManager(_$AppDatabase db, $PhotosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PhotosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PhotosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PhotosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> photoId = const Value.absent(),
                Value<int> recordId = const Value.absent(),
                Value<String> filePath = const Value.absent(),
              }) => PhotosCompanion(
                photoId: photoId,
                recordId: recordId,
                filePath: filePath,
              ),
          createCompanionCallback:
              ({
                Value<int> photoId = const Value.absent(),
                required int recordId,
                required String filePath,
              }) => PhotosCompanion.insert(
                photoId: photoId,
                recordId: recordId,
                filePath: filePath,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$PhotosTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({recordId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (recordId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.recordId,
                                referencedTable: $$PhotosTableReferences
                                    ._recordIdTable(db),
                                referencedColumn: $$PhotosTableReferences
                                    ._recordIdTable(db)
                                    .recordId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PhotosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PhotosTable,
      Photo,
      $$PhotosTableFilterComposer,
      $$PhotosTableOrderingComposer,
      $$PhotosTableAnnotationComposer,
      $$PhotosTableCreateCompanionBuilder,
      $$PhotosTableUpdateCompanionBuilder,
      (Photo, $$PhotosTableReferences),
      Photo,
      PrefetchHooks Function({bool recordId})
    >;
typedef $$MemosTableCreateCompanionBuilder =
    MemosCompanion Function({
      Value<int> memoId,
      required int recordId,
      required String memoText,
      Value<bool> isVoiceMemo,
    });
typedef $$MemosTableUpdateCompanionBuilder =
    MemosCompanion Function({
      Value<int> memoId,
      Value<int> recordId,
      Value<String> memoText,
      Value<bool> isVoiceMemo,
    });

final class $$MemosTableReferences
    extends BaseReferences<_$AppDatabase, $MemosTable, Memo> {
  $$MemosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RecordsTable _recordIdTable(_$AppDatabase db) =>
      db.records.createAlias(
        $_aliasNameGenerator(db.memos.recordId, db.records.recordId),
      );

  $$RecordsTableProcessedTableManager get recordId {
    final $_column = $_itemColumn<int>('record_id')!;

    final manager = $$RecordsTableTableManager(
      $_db,
      $_db.records,
    ).filter((f) => f.recordId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MemosTableFilterComposer extends Composer<_$AppDatabase, $MemosTable> {
  $$MemosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get memoId => $composableBuilder(
    column: $table.memoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memoText => $composableBuilder(
    column: $table.memoText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isVoiceMemo => $composableBuilder(
    column: $table.isVoiceMemo,
    builder: (column) => ColumnFilters(column),
  );

  $$RecordsTableFilterComposer get recordId {
    final $$RecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordId,
      referencedTable: $db.records,
      getReferencedColumn: (t) => t.recordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecordsTableFilterComposer(
            $db: $db,
            $table: $db.records,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MemosTableOrderingComposer
    extends Composer<_$AppDatabase, $MemosTable> {
  $$MemosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get memoId => $composableBuilder(
    column: $table.memoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memoText => $composableBuilder(
    column: $table.memoText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isVoiceMemo => $composableBuilder(
    column: $table.isVoiceMemo,
    builder: (column) => ColumnOrderings(column),
  );

  $$RecordsTableOrderingComposer get recordId {
    final $$RecordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordId,
      referencedTable: $db.records,
      getReferencedColumn: (t) => t.recordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecordsTableOrderingComposer(
            $db: $db,
            $table: $db.records,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MemosTableAnnotationComposer
    extends Composer<_$AppDatabase, $MemosTable> {
  $$MemosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get memoId =>
      $composableBuilder(column: $table.memoId, builder: (column) => column);

  GeneratedColumn<String> get memoText =>
      $composableBuilder(column: $table.memoText, builder: (column) => column);

  GeneratedColumn<bool> get isVoiceMemo => $composableBuilder(
    column: $table.isVoiceMemo,
    builder: (column) => column,
  );

  $$RecordsTableAnnotationComposer get recordId {
    final $$RecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordId,
      referencedTable: $db.records,
      getReferencedColumn: (t) => t.recordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.records,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MemosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MemosTable,
          Memo,
          $$MemosTableFilterComposer,
          $$MemosTableOrderingComposer,
          $$MemosTableAnnotationComposer,
          $$MemosTableCreateCompanionBuilder,
          $$MemosTableUpdateCompanionBuilder,
          (Memo, $$MemosTableReferences),
          Memo,
          PrefetchHooks Function({bool recordId})
        > {
  $$MemosTableTableManager(_$AppDatabase db, $MemosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MemosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MemosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MemosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> memoId = const Value.absent(),
                Value<int> recordId = const Value.absent(),
                Value<String> memoText = const Value.absent(),
                Value<bool> isVoiceMemo = const Value.absent(),
              }) => MemosCompanion(
                memoId: memoId,
                recordId: recordId,
                memoText: memoText,
                isVoiceMemo: isVoiceMemo,
              ),
          createCompanionCallback:
              ({
                Value<int> memoId = const Value.absent(),
                required int recordId,
                required String memoText,
                Value<bool> isVoiceMemo = const Value.absent(),
              }) => MemosCompanion.insert(
                memoId: memoId,
                recordId: recordId,
                memoText: memoText,
                isVoiceMemo: isVoiceMemo,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$MemosTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({recordId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (recordId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.recordId,
                                referencedTable: $$MemosTableReferences
                                    ._recordIdTable(db),
                                referencedColumn: $$MemosTableReferences
                                    ._recordIdTable(db)
                                    .recordId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MemosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MemosTable,
      Memo,
      $$MemosTableFilterComposer,
      $$MemosTableOrderingComposer,
      $$MemosTableAnnotationComposer,
      $$MemosTableCreateCompanionBuilder,
      $$MemosTableUpdateCompanionBuilder,
      (Memo, $$MemosTableReferences),
      Memo,
      PrefetchHooks Function({bool recordId})
    >;
typedef $$AmcDraftRecordsTableCreateCompanionBuilder =
    AmcDraftRecordsCompanion Function({
      Value<int> draftRecordId,
      Value<int?> obsEventId,
      Value<String> currentBody,
      Value<String> visibility,
      required AmcSyncState syncState,
      Value<String?> remoteRecordId,
      Value<String?> currentRevisionId,
      required int updatedAtMillis,
      Value<bool> deleted,
    });
typedef $$AmcDraftRecordsTableUpdateCompanionBuilder =
    AmcDraftRecordsCompanion Function({
      Value<int> draftRecordId,
      Value<int?> obsEventId,
      Value<String> currentBody,
      Value<String> visibility,
      Value<AmcSyncState> syncState,
      Value<String?> remoteRecordId,
      Value<String?> currentRevisionId,
      Value<int> updatedAtMillis,
      Value<bool> deleted,
    });

final class $$AmcDraftRecordsTableReferences
    extends
        BaseReferences<_$AppDatabase, $AmcDraftRecordsTable, AmcDraftRecord> {
  $$AmcDraftRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$AmcRecordRevisionsTable, List<AmcRecordRevision>>
  _amcRecordRevisionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.amcRecordRevisions,
        aliasName: $_aliasNameGenerator(
          db.amcDraftRecords.draftRecordId,
          db.amcRecordRevisions.draftRecordId,
        ),
      );

  $$AmcRecordRevisionsTableProcessedTableManager get amcRecordRevisionsRefs {
    final manager =
        $$AmcRecordRevisionsTableTableManager(
          $_db,
          $_db.amcRecordRevisions,
        ).filter(
          (f) => f.draftRecordId.draftRecordId.sqlEquals(
            $_itemColumn<int>('draft_record_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _amcRecordRevisionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AmcAttachmentQueueTable, List<AmcAttachment>>
  _amcAttachmentQueueRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.amcAttachmentQueue,
        aliasName: $_aliasNameGenerator(
          db.amcDraftRecords.draftRecordId,
          db.amcAttachmentQueue.draftRecordId,
        ),
      );

  $$AmcAttachmentQueueTableProcessedTableManager get amcAttachmentQueueRefs {
    final manager =
        $$AmcAttachmentQueueTableTableManager(
          $_db,
          $_db.amcAttachmentQueue,
        ).filter(
          (f) => f.draftRecordId.draftRecordId.sqlEquals(
            $_itemColumn<int>('draft_record_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _amcAttachmentQueueRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AmcDraftRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $AmcDraftRecordsTable> {
  $$AmcDraftRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get draftRecordId => $composableBuilder(
    column: $table.draftRecordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get obsEventId => $composableBuilder(
    column: $table.obsEventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currentBody => $composableBuilder(
    column: $table.currentBody,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get visibility => $composableBuilder(
    column: $table.visibility,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AmcSyncState, AmcSyncState, String>
  get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get remoteRecordId => $composableBuilder(
    column: $table.remoteRecordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currentRevisionId => $composableBuilder(
    column: $table.currentRevisionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtMillis => $composableBuilder(
    column: $table.updatedAtMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> amcRecordRevisionsRefs(
    Expression<bool> Function($$AmcRecordRevisionsTableFilterComposer f) f,
  ) {
    final $$AmcRecordRevisionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.draftRecordId,
      referencedTable: $db.amcRecordRevisions,
      getReferencedColumn: (t) => t.draftRecordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AmcRecordRevisionsTableFilterComposer(
            $db: $db,
            $table: $db.amcRecordRevisions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> amcAttachmentQueueRefs(
    Expression<bool> Function($$AmcAttachmentQueueTableFilterComposer f) f,
  ) {
    final $$AmcAttachmentQueueTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.draftRecordId,
      referencedTable: $db.amcAttachmentQueue,
      getReferencedColumn: (t) => t.draftRecordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AmcAttachmentQueueTableFilterComposer(
            $db: $db,
            $table: $db.amcAttachmentQueue,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AmcDraftRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $AmcDraftRecordsTable> {
  $$AmcDraftRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get draftRecordId => $composableBuilder(
    column: $table.draftRecordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get obsEventId => $composableBuilder(
    column: $table.obsEventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currentBody => $composableBuilder(
    column: $table.currentBody,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get visibility => $composableBuilder(
    column: $table.visibility,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteRecordId => $composableBuilder(
    column: $table.remoteRecordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currentRevisionId => $composableBuilder(
    column: $table.currentRevisionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtMillis => $composableBuilder(
    column: $table.updatedAtMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AmcDraftRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AmcDraftRecordsTable> {
  $$AmcDraftRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get draftRecordId => $composableBuilder(
    column: $table.draftRecordId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get obsEventId => $composableBuilder(
    column: $table.obsEventId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currentBody => $composableBuilder(
    column: $table.currentBody,
    builder: (column) => column,
  );

  GeneratedColumn<String> get visibility => $composableBuilder(
    column: $table.visibility,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<AmcSyncState, String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<String> get remoteRecordId => $composableBuilder(
    column: $table.remoteRecordId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currentRevisionId => $composableBuilder(
    column: $table.currentRevisionId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtMillis => $composableBuilder(
    column: $table.updatedAtMillis,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  Expression<T> amcRecordRevisionsRefs<T extends Object>(
    Expression<T> Function($$AmcRecordRevisionsTableAnnotationComposer a) f,
  ) {
    final $$AmcRecordRevisionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.draftRecordId,
          referencedTable: $db.amcRecordRevisions,
          getReferencedColumn: (t) => t.draftRecordId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AmcRecordRevisionsTableAnnotationComposer(
                $db: $db,
                $table: $db.amcRecordRevisions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> amcAttachmentQueueRefs<T extends Object>(
    Expression<T> Function($$AmcAttachmentQueueTableAnnotationComposer a) f,
  ) {
    final $$AmcAttachmentQueueTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.draftRecordId,
          referencedTable: $db.amcAttachmentQueue,
          getReferencedColumn: (t) => t.draftRecordId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AmcAttachmentQueueTableAnnotationComposer(
                $db: $db,
                $table: $db.amcAttachmentQueue,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$AmcDraftRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AmcDraftRecordsTable,
          AmcDraftRecord,
          $$AmcDraftRecordsTableFilterComposer,
          $$AmcDraftRecordsTableOrderingComposer,
          $$AmcDraftRecordsTableAnnotationComposer,
          $$AmcDraftRecordsTableCreateCompanionBuilder,
          $$AmcDraftRecordsTableUpdateCompanionBuilder,
          (AmcDraftRecord, $$AmcDraftRecordsTableReferences),
          AmcDraftRecord,
          PrefetchHooks Function({
            bool amcRecordRevisionsRefs,
            bool amcAttachmentQueueRefs,
          })
        > {
  $$AmcDraftRecordsTableTableManager(
    _$AppDatabase db,
    $AmcDraftRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AmcDraftRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AmcDraftRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AmcDraftRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> draftRecordId = const Value.absent(),
                Value<int?> obsEventId = const Value.absent(),
                Value<String> currentBody = const Value.absent(),
                Value<String> visibility = const Value.absent(),
                Value<AmcSyncState> syncState = const Value.absent(),
                Value<String?> remoteRecordId = const Value.absent(),
                Value<String?> currentRevisionId = const Value.absent(),
                Value<int> updatedAtMillis = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
              }) => AmcDraftRecordsCompanion(
                draftRecordId: draftRecordId,
                obsEventId: obsEventId,
                currentBody: currentBody,
                visibility: visibility,
                syncState: syncState,
                remoteRecordId: remoteRecordId,
                currentRevisionId: currentRevisionId,
                updatedAtMillis: updatedAtMillis,
                deleted: deleted,
              ),
          createCompanionCallback:
              ({
                Value<int> draftRecordId = const Value.absent(),
                Value<int?> obsEventId = const Value.absent(),
                Value<String> currentBody = const Value.absent(),
                Value<String> visibility = const Value.absent(),
                required AmcSyncState syncState,
                Value<String?> remoteRecordId = const Value.absent(),
                Value<String?> currentRevisionId = const Value.absent(),
                required int updatedAtMillis,
                Value<bool> deleted = const Value.absent(),
              }) => AmcDraftRecordsCompanion.insert(
                draftRecordId: draftRecordId,
                obsEventId: obsEventId,
                currentBody: currentBody,
                visibility: visibility,
                syncState: syncState,
                remoteRecordId: remoteRecordId,
                currentRevisionId: currentRevisionId,
                updatedAtMillis: updatedAtMillis,
                deleted: deleted,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AmcDraftRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                amcRecordRevisionsRefs = false,
                amcAttachmentQueueRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (amcRecordRevisionsRefs) db.amcRecordRevisions,
                    if (amcAttachmentQueueRefs) db.amcAttachmentQueue,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (amcRecordRevisionsRefs)
                        await $_getPrefetchedData<
                          AmcDraftRecord,
                          $AmcDraftRecordsTable,
                          AmcRecordRevision
                        >(
                          currentTable: table,
                          referencedTable: $$AmcDraftRecordsTableReferences
                              ._amcRecordRevisionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AmcDraftRecordsTableReferences(
                                db,
                                table,
                                p0,
                              ).amcRecordRevisionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.draftRecordId == item.draftRecordId,
                              ),
                          typedResults: items,
                        ),
                      if (amcAttachmentQueueRefs)
                        await $_getPrefetchedData<
                          AmcDraftRecord,
                          $AmcDraftRecordsTable,
                          AmcAttachment
                        >(
                          currentTable: table,
                          referencedTable: $$AmcDraftRecordsTableReferences
                              ._amcAttachmentQueueRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AmcDraftRecordsTableReferences(
                                db,
                                table,
                                p0,
                              ).amcAttachmentQueueRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.draftRecordId == item.draftRecordId,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AmcDraftRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AmcDraftRecordsTable,
      AmcDraftRecord,
      $$AmcDraftRecordsTableFilterComposer,
      $$AmcDraftRecordsTableOrderingComposer,
      $$AmcDraftRecordsTableAnnotationComposer,
      $$AmcDraftRecordsTableCreateCompanionBuilder,
      $$AmcDraftRecordsTableUpdateCompanionBuilder,
      (AmcDraftRecord, $$AmcDraftRecordsTableReferences),
      AmcDraftRecord,
      PrefetchHooks Function({
        bool amcRecordRevisionsRefs,
        bool amcAttachmentQueueRefs,
      })
    >;
typedef $$AmcRecordRevisionsTableCreateCompanionBuilder =
    AmcRecordRevisionsCompanion Function({
      Value<int> revisionLocalId,
      required int draftRecordId,
      required String body,
      required String idempotencyKey,
      Value<String?> remoteRevisionId,
      required int createdAtMillis,
    });
typedef $$AmcRecordRevisionsTableUpdateCompanionBuilder =
    AmcRecordRevisionsCompanion Function({
      Value<int> revisionLocalId,
      Value<int> draftRecordId,
      Value<String> body,
      Value<String> idempotencyKey,
      Value<String?> remoteRevisionId,
      Value<int> createdAtMillis,
    });

final class $$AmcRecordRevisionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $AmcRecordRevisionsTable,
          AmcRecordRevision
        > {
  $$AmcRecordRevisionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AmcDraftRecordsTable _draftRecordIdTable(_$AppDatabase db) =>
      db.amcDraftRecords.createAlias(
        $_aliasNameGenerator(
          db.amcRecordRevisions.draftRecordId,
          db.amcDraftRecords.draftRecordId,
        ),
      );

  $$AmcDraftRecordsTableProcessedTableManager get draftRecordId {
    final $_column = $_itemColumn<int>('draft_record_id')!;

    final manager = $$AmcDraftRecordsTableTableManager(
      $_db,
      $_db.amcDraftRecords,
    ).filter((f) => f.draftRecordId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_draftRecordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AmcRecordRevisionsTableFilterComposer
    extends Composer<_$AppDatabase, $AmcRecordRevisionsTable> {
  $$AmcRecordRevisionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get revisionLocalId => $composableBuilder(
    column: $table.revisionLocalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteRevisionId => $composableBuilder(
    column: $table.remoteRevisionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMillis => $composableBuilder(
    column: $table.createdAtMillis,
    builder: (column) => ColumnFilters(column),
  );

  $$AmcDraftRecordsTableFilterComposer get draftRecordId {
    final $$AmcDraftRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.draftRecordId,
      referencedTable: $db.amcDraftRecords,
      getReferencedColumn: (t) => t.draftRecordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AmcDraftRecordsTableFilterComposer(
            $db: $db,
            $table: $db.amcDraftRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AmcRecordRevisionsTableOrderingComposer
    extends Composer<_$AppDatabase, $AmcRecordRevisionsTable> {
  $$AmcRecordRevisionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get revisionLocalId => $composableBuilder(
    column: $table.revisionLocalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteRevisionId => $composableBuilder(
    column: $table.remoteRevisionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMillis => $composableBuilder(
    column: $table.createdAtMillis,
    builder: (column) => ColumnOrderings(column),
  );

  $$AmcDraftRecordsTableOrderingComposer get draftRecordId {
    final $$AmcDraftRecordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.draftRecordId,
      referencedTable: $db.amcDraftRecords,
      getReferencedColumn: (t) => t.draftRecordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AmcDraftRecordsTableOrderingComposer(
            $db: $db,
            $table: $db.amcDraftRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AmcRecordRevisionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AmcRecordRevisionsTable> {
  $$AmcRecordRevisionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get revisionLocalId => $composableBuilder(
    column: $table.revisionLocalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteRevisionId => $composableBuilder(
    column: $table.remoteRevisionId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtMillis => $composableBuilder(
    column: $table.createdAtMillis,
    builder: (column) => column,
  );

  $$AmcDraftRecordsTableAnnotationComposer get draftRecordId {
    final $$AmcDraftRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.draftRecordId,
      referencedTable: $db.amcDraftRecords,
      getReferencedColumn: (t) => t.draftRecordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AmcDraftRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.amcDraftRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AmcRecordRevisionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AmcRecordRevisionsTable,
          AmcRecordRevision,
          $$AmcRecordRevisionsTableFilterComposer,
          $$AmcRecordRevisionsTableOrderingComposer,
          $$AmcRecordRevisionsTableAnnotationComposer,
          $$AmcRecordRevisionsTableCreateCompanionBuilder,
          $$AmcRecordRevisionsTableUpdateCompanionBuilder,
          (AmcRecordRevision, $$AmcRecordRevisionsTableReferences),
          AmcRecordRevision,
          PrefetchHooks Function({bool draftRecordId})
        > {
  $$AmcRecordRevisionsTableTableManager(
    _$AppDatabase db,
    $AmcRecordRevisionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AmcRecordRevisionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AmcRecordRevisionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AmcRecordRevisionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> revisionLocalId = const Value.absent(),
                Value<int> draftRecordId = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<String> idempotencyKey = const Value.absent(),
                Value<String?> remoteRevisionId = const Value.absent(),
                Value<int> createdAtMillis = const Value.absent(),
              }) => AmcRecordRevisionsCompanion(
                revisionLocalId: revisionLocalId,
                draftRecordId: draftRecordId,
                body: body,
                idempotencyKey: idempotencyKey,
                remoteRevisionId: remoteRevisionId,
                createdAtMillis: createdAtMillis,
              ),
          createCompanionCallback:
              ({
                Value<int> revisionLocalId = const Value.absent(),
                required int draftRecordId,
                required String body,
                required String idempotencyKey,
                Value<String?> remoteRevisionId = const Value.absent(),
                required int createdAtMillis,
              }) => AmcRecordRevisionsCompanion.insert(
                revisionLocalId: revisionLocalId,
                draftRecordId: draftRecordId,
                body: body,
                idempotencyKey: idempotencyKey,
                remoteRevisionId: remoteRevisionId,
                createdAtMillis: createdAtMillis,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AmcRecordRevisionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({draftRecordId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (draftRecordId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.draftRecordId,
                                referencedTable:
                                    $$AmcRecordRevisionsTableReferences
                                        ._draftRecordIdTable(db),
                                referencedColumn:
                                    $$AmcRecordRevisionsTableReferences
                                        ._draftRecordIdTable(db)
                                        .draftRecordId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AmcRecordRevisionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AmcRecordRevisionsTable,
      AmcRecordRevision,
      $$AmcRecordRevisionsTableFilterComposer,
      $$AmcRecordRevisionsTableOrderingComposer,
      $$AmcRecordRevisionsTableAnnotationComposer,
      $$AmcRecordRevisionsTableCreateCompanionBuilder,
      $$AmcRecordRevisionsTableUpdateCompanionBuilder,
      (AmcRecordRevision, $$AmcRecordRevisionsTableReferences),
      AmcRecordRevision,
      PrefetchHooks Function({bool draftRecordId})
    >;
typedef $$AmcAttachmentQueueTableCreateCompanionBuilder =
    AmcAttachmentQueueCompanion Function({
      Value<int> attachmentId,
      required int draftRecordId,
      required String localUri,
      required String mimeType,
      required AmcAttachmentState state,
      Value<String?> storagePath,
      Value<String?> remoteAttachmentId,
      Value<int> attemptNumber,
      Value<String?> lastErrorCode,
      Value<int?> expiresAtMillis,
      Value<String?> checksum,
    });
typedef $$AmcAttachmentQueueTableUpdateCompanionBuilder =
    AmcAttachmentQueueCompanion Function({
      Value<int> attachmentId,
      Value<int> draftRecordId,
      Value<String> localUri,
      Value<String> mimeType,
      Value<AmcAttachmentState> state,
      Value<String?> storagePath,
      Value<String?> remoteAttachmentId,
      Value<int> attemptNumber,
      Value<String?> lastErrorCode,
      Value<int?> expiresAtMillis,
      Value<String?> checksum,
    });

final class $$AmcAttachmentQueueTableReferences
    extends
        BaseReferences<_$AppDatabase, $AmcAttachmentQueueTable, AmcAttachment> {
  $$AmcAttachmentQueueTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AmcDraftRecordsTable _draftRecordIdTable(_$AppDatabase db) =>
      db.amcDraftRecords.createAlias(
        $_aliasNameGenerator(
          db.amcAttachmentQueue.draftRecordId,
          db.amcDraftRecords.draftRecordId,
        ),
      );

  $$AmcDraftRecordsTableProcessedTableManager get draftRecordId {
    final $_column = $_itemColumn<int>('draft_record_id')!;

    final manager = $$AmcDraftRecordsTableTableManager(
      $_db,
      $_db.amcDraftRecords,
    ).filter((f) => f.draftRecordId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_draftRecordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AmcAttachmentQueueTableFilterComposer
    extends Composer<_$AppDatabase, $AmcAttachmentQueueTable> {
  $$AmcAttachmentQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get attachmentId => $composableBuilder(
    column: $table.attachmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localUri => $composableBuilder(
    column: $table.localUri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AmcAttachmentState, AmcAttachmentState, String>
  get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get storagePath => $composableBuilder(
    column: $table.storagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteAttachmentId => $composableBuilder(
    column: $table.remoteAttachmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attemptNumber => $composableBuilder(
    column: $table.attemptNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expiresAtMillis => $composableBuilder(
    column: $table.expiresAtMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checksum => $composableBuilder(
    column: $table.checksum,
    builder: (column) => ColumnFilters(column),
  );

  $$AmcDraftRecordsTableFilterComposer get draftRecordId {
    final $$AmcDraftRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.draftRecordId,
      referencedTable: $db.amcDraftRecords,
      getReferencedColumn: (t) => t.draftRecordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AmcDraftRecordsTableFilterComposer(
            $db: $db,
            $table: $db.amcDraftRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AmcAttachmentQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $AmcAttachmentQueueTable> {
  $$AmcAttachmentQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get attachmentId => $composableBuilder(
    column: $table.attachmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localUri => $composableBuilder(
    column: $table.localUri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storagePath => $composableBuilder(
    column: $table.storagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteAttachmentId => $composableBuilder(
    column: $table.remoteAttachmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptNumber => $composableBuilder(
    column: $table.attemptNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expiresAtMillis => $composableBuilder(
    column: $table.expiresAtMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checksum => $composableBuilder(
    column: $table.checksum,
    builder: (column) => ColumnOrderings(column),
  );

  $$AmcDraftRecordsTableOrderingComposer get draftRecordId {
    final $$AmcDraftRecordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.draftRecordId,
      referencedTable: $db.amcDraftRecords,
      getReferencedColumn: (t) => t.draftRecordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AmcDraftRecordsTableOrderingComposer(
            $db: $db,
            $table: $db.amcDraftRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AmcAttachmentQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $AmcAttachmentQueueTable> {
  $$AmcAttachmentQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get attachmentId => $composableBuilder(
    column: $table.attachmentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localUri =>
      $composableBuilder(column: $table.localUri, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AmcAttachmentState, String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get storagePath => $composableBuilder(
    column: $table.storagePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteAttachmentId => $composableBuilder(
    column: $table.remoteAttachmentId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attemptNumber => $composableBuilder(
    column: $table.attemptNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get expiresAtMillis => $composableBuilder(
    column: $table.expiresAtMillis,
    builder: (column) => column,
  );

  GeneratedColumn<String> get checksum =>
      $composableBuilder(column: $table.checksum, builder: (column) => column);

  $$AmcDraftRecordsTableAnnotationComposer get draftRecordId {
    final $$AmcDraftRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.draftRecordId,
      referencedTable: $db.amcDraftRecords,
      getReferencedColumn: (t) => t.draftRecordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AmcDraftRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.amcDraftRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AmcAttachmentQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AmcAttachmentQueueTable,
          AmcAttachment,
          $$AmcAttachmentQueueTableFilterComposer,
          $$AmcAttachmentQueueTableOrderingComposer,
          $$AmcAttachmentQueueTableAnnotationComposer,
          $$AmcAttachmentQueueTableCreateCompanionBuilder,
          $$AmcAttachmentQueueTableUpdateCompanionBuilder,
          (AmcAttachment, $$AmcAttachmentQueueTableReferences),
          AmcAttachment,
          PrefetchHooks Function({bool draftRecordId})
        > {
  $$AmcAttachmentQueueTableTableManager(
    _$AppDatabase db,
    $AmcAttachmentQueueTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AmcAttachmentQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AmcAttachmentQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AmcAttachmentQueueTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> attachmentId = const Value.absent(),
                Value<int> draftRecordId = const Value.absent(),
                Value<String> localUri = const Value.absent(),
                Value<String> mimeType = const Value.absent(),
                Value<AmcAttachmentState> state = const Value.absent(),
                Value<String?> storagePath = const Value.absent(),
                Value<String?> remoteAttachmentId = const Value.absent(),
                Value<int> attemptNumber = const Value.absent(),
                Value<String?> lastErrorCode = const Value.absent(),
                Value<int?> expiresAtMillis = const Value.absent(),
                Value<String?> checksum = const Value.absent(),
              }) => AmcAttachmentQueueCompanion(
                attachmentId: attachmentId,
                draftRecordId: draftRecordId,
                localUri: localUri,
                mimeType: mimeType,
                state: state,
                storagePath: storagePath,
                remoteAttachmentId: remoteAttachmentId,
                attemptNumber: attemptNumber,
                lastErrorCode: lastErrorCode,
                expiresAtMillis: expiresAtMillis,
                checksum: checksum,
              ),
          createCompanionCallback:
              ({
                Value<int> attachmentId = const Value.absent(),
                required int draftRecordId,
                required String localUri,
                required String mimeType,
                required AmcAttachmentState state,
                Value<String?> storagePath = const Value.absent(),
                Value<String?> remoteAttachmentId = const Value.absent(),
                Value<int> attemptNumber = const Value.absent(),
                Value<String?> lastErrorCode = const Value.absent(),
                Value<int?> expiresAtMillis = const Value.absent(),
                Value<String?> checksum = const Value.absent(),
              }) => AmcAttachmentQueueCompanion.insert(
                attachmentId: attachmentId,
                draftRecordId: draftRecordId,
                localUri: localUri,
                mimeType: mimeType,
                state: state,
                storagePath: storagePath,
                remoteAttachmentId: remoteAttachmentId,
                attemptNumber: attemptNumber,
                lastErrorCode: lastErrorCode,
                expiresAtMillis: expiresAtMillis,
                checksum: checksum,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AmcAttachmentQueueTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({draftRecordId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (draftRecordId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.draftRecordId,
                                referencedTable:
                                    $$AmcAttachmentQueueTableReferences
                                        ._draftRecordIdTable(db),
                                referencedColumn:
                                    $$AmcAttachmentQueueTableReferences
                                        ._draftRecordIdTable(db)
                                        .draftRecordId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AmcAttachmentQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AmcAttachmentQueueTable,
      AmcAttachment,
      $$AmcAttachmentQueueTableFilterComposer,
      $$AmcAttachmentQueueTableOrderingComposer,
      $$AmcAttachmentQueueTableAnnotationComposer,
      $$AmcAttachmentQueueTableCreateCompanionBuilder,
      $$AmcAttachmentQueueTableUpdateCompanionBuilder,
      (AmcAttachment, $$AmcAttachmentQueueTableReferences),
      AmcAttachment,
      PrefetchHooks Function({bool draftRecordId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$EventsTableTableManager get events =>
      $$EventsTableTableManager(_db, _db.events);
  $$ObservationEventsTableTableManager get observationEvents =>
      $$ObservationEventsTableTableManager(_db, _db.observationEvents);
  $$RecordsTableTableManager get records =>
      $$RecordsTableTableManager(_db, _db.records);
  $$PhotosTableTableManager get photos =>
      $$PhotosTableTableManager(_db, _db.photos);
  $$MemosTableTableManager get memos =>
      $$MemosTableTableManager(_db, _db.memos);
  $$AmcDraftRecordsTableTableManager get amcDraftRecords =>
      $$AmcDraftRecordsTableTableManager(_db, _db.amcDraftRecords);
  $$AmcRecordRevisionsTableTableManager get amcRecordRevisions =>
      $$AmcRecordRevisionsTableTableManager(_db, _db.amcRecordRevisions);
  $$AmcAttachmentQueueTableTableManager get amcAttachmentQueue =>
      $$AmcAttachmentQueueTableTableManager(_db, _db.amcAttachmentQueue);
}

import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'event_dao.g.dart';

@DriftAccessor(tables: [Events])
class EventDao extends DatabaseAccessor<AppDatabase> with _$EventDaoMixin {
  EventDao(super.attachedDatabase);

  /// 同期時の一括 upsert（googleEventId UNIQUE で REPLACE）。
  Future<void> upsertAll(List<EventsCompanion> rows) async {
    await batch((b) {
      b.insertAll(events, rows, mode: InsertMode.replace);
    });
  }

  /// 単件 upsert。生成された eventId を返す。
  Future<int> upsert(EventsCompanion event) =>
      into(events).insert(event, mode: InsertMode.replace);

  Future<void> deleteById(int eventId) =>
      (delete(events)..where((t) => t.eventId.equals(eventId))).go();

  /// 今日以降のイベントを開始時刻昇順で監視。
  Stream<List<Event>> watchUpcoming(int fromMillis) {
    return (select(events)
          ..where((t) => t.startTime.isBiggerOrEqualValue(fromMillis))
          ..orderBy([(t) => OrderingTerm.asc(t.startTime)]))
        .watch();
  }

  Future<List<Event>> getUpcoming(int fromMillis) {
    return (select(events)
          ..where((t) => t.startTime.isBiggerOrEqualValue(fromMillis))
          ..orderBy([(t) => OrderingTerm.asc(t.startTime)]))
        .get();
  }

  /// 全イベントを開始時刻降順で監視（履歴用）。
  Stream<List<Event>> watchAll() {
    return (select(events)
          ..orderBy([(t) => OrderingTerm.desc(t.startTime)]))
        .watch();
  }

  Future<Event?> findById(int eventId) =>
      (select(events)..where((t) => t.eventId.equals(eventId)))
          .getSingleOrNull();

  Future<Event?> findByGoogleId(String googleId) =>
      (select(events)..where((t) => t.googleEventId.equals(googleId)))
          .getSingleOrNull();

  /// 現在進行中のイベントを 1 件取得。
  Future<Event?> findOngoing(int now) {
    return (select(events)
          ..where((t) =>
              t.startTime.isSmallerOrEqualValue(now) &
              t.endTime.isBiggerThanValue(now))
          ..limit(1))
        .getSingleOrNull();
  }

  /// 現在進行中のイベントを監視（開始時刻降順で最新 1 件）。
  Stream<Event?> watchOngoing(int now) {
    return (select(events)
          ..where((t) =>
              t.startTime.isSmallerOrEqualValue(now) &
              t.endTime.isBiggerThanValue(now))
          ..orderBy([(t) => OrderingTerm.desc(t.startTime)])
          ..limit(1))
        .watchSingleOrNull();
  }

  /// 古いキャッシュを削除（同期時）。
  /// 不変条件(§9): `local-draft:%` は削除対象から除外する。
  Future<void> deleteStaleEvents(List<String> activeGoogleIds) async {
    if (activeGoogleIds.isEmpty) {
      await customUpdate(
        "DELETE FROM events WHERE google_event_id NOT LIKE 'local-draft:%'",
        updates: {events},
        updateKind: UpdateKind.delete,
      );
      return;
    }
    final placeholders = List.filled(activeGoogleIds.length, '?').join(',');
    await customUpdate(
      '''
      DELETE FROM events
      WHERE google_event_id NOT LIKE 'local-draft:%'
        AND google_event_id NOT IN ($placeholders)
      ''',
      variables: activeGoogleIds.map((g) => Variable.withString(g)).toList(),
      updates: {events},
      updateKind: UpdateKind.delete,
    );
  }
}

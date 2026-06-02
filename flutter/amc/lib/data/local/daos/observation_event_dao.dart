import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'observation_event_dao.g.dart';

@DriftAccessor(tables: [ObservationEvents])
class ObservationEventDao extends DatabaseAccessor<AppDatabase>
    with _$ObservationEventDaoMixin {
  ObservationEventDao(super.attachedDatabase);

  /// 新規 ObservationEvent を挿入する。
  /// googleEventId が UNIQUE のため重複時は IGNORE（既存行を保持）。
  ///
  /// 注意(§9 findOrCreate): drift の insertOrIgnore は ignore 時の戻り値が
  /// 信頼できないため、呼び出し側(Repository)は本メソッドの戻り値に依存せず
  /// [findByGoogleEventId] で既存行を解決すること。
  Future<int> insertOrIgnore(ObservationEventsCompanion entity) =>
      into(observationEvents).insert(entity, mode: InsertMode.insertOrIgnore);

  Future<ObservationEvent?> findByGoogleEventId(String googleEventId) =>
      (select(observationEvents)
            ..where((t) => t.googleEventId.equals(googleEventId)))
          .getSingleOrNull();

  Future<ObservationEvent?> findById(int id) =>
      (select(observationEvents)..where((t) => t.obsEventId.equals(id)))
          .getSingleOrNull();

  /// 下書き確定時に local-draft の googleEventId を実 ID へ付け替える（§9）。
  Future<void> updateGoogleId({
    required String oldGoogleId,
    required String newGoogleId,
    required String title,
    required int startTime,
    required int endTime,
  }) async {
    await customUpdate(
      '''
      UPDATE observation_events
      SET google_event_id = ?, title = ?, start_time = ?, end_time = ?
      WHERE google_event_id = ?
      ''',
      variables: [
        Variable.withString(newGoogleId),
        Variable.withString(title),
        Variable.withInt(startTime),
        Variable.withInt(endTime),
        Variable.withString(oldGoogleId),
      ],
      updates: {observationEvents},
      updateKind: UpdateKind.update,
    );
  }

  /// 履歴・分析向け：全件を開始時刻降順で監視。
  Stream<List<ObservationEvent>> watchAll() {
    return (select(observationEvents)
          ..orderBy([(t) => OrderingTerm.desc(t.startTime)]))
        .watch();
  }
}
